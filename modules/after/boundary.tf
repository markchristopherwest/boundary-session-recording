# resource "random_shuffle" "group" {
#   input = [
#     for o in boundary_user.user : o.id
#   ]
#   result_count = floor(length(var.users) / 4)
#   count        = floor(length(var.users) / 2)
# }

resource "random_pet" "group" {
  length = 2
  count  = length(var.users) / 2
}

variable "users" {
  type = set(string)
  default = [
    "kristopher",
    "kris",
    "chris",
    "swarna",
    "mark",
    "julia",
  ]
}

resource "boundary_scope" "global" {
  global_scope = true
  scope_id     = "global"
}

# resource "boundary_scope" "org_contractors" {
#   name        = "${var.iteration_name}-org-contractors"
#   description = "${var.iteration_name} Contractors Users"
#   scope_id    = boundary_scope.global.id
#   auto_create_admin_role   = true
#   auto_create_default_role = true
# }

resource "boundary_role" "org_contractors_admin" {
  scope_id       = boundary_scope.global.id
  grant_scope_id = boundary_scope.linux.id
  grant_strings  = ["ids=*;type=*;actions=*"]
  principal_ids  = ["u_auth"]
}

# resource "boundary_scope" "contractors_linux" {
#   name                   = "Linux Project"
#   description            = "Contractors Linux Project"
#   scope_id               = boundary_scope.org_contractors.id
#   auto_create_admin_role = true
# }

# resource "boundary_scope" "contractors_windows" {
#   name                   = "Windows Project"
#   description            = "Contractors Windows Project"
#   scope_id               = boundary_scope.org_contractors.id
#   auto_create_admin_role = true
# }

resource "boundary_scope" "org" {
  name                     = "${var.iteration_name}-org"
  description              = "${var.iteration_name} Exempt Users"
  scope_id                 = boundary_scope.global.id
  auto_create_admin_role   = true
  auto_create_default_role = true
}

resource "boundary_role" "org_admin" {
  scope_id       = boundary_scope.global.id
  grant_scope_id = boundary_scope.org.id
  grant_strings  = ["ids=*;type=*;actions=*"]
  principal_ids  = ["u_auth"]
}

resource "boundary_scope" "linux" {
  name                   = "Linux Project"
  description            = "Linux Things"
  scope_id               = boundary_scope.org.id
  auto_create_admin_role = true
}

resource "boundary_scope" "windows" {
  name                   = "Windows Project"
  description            = "Windows Things"
  scope_id               = boundary_scope.org.id
  auto_create_admin_role = true
}

resource "boundary_user" "user" {
  for_each    = var.users
  name        = each.key
  description = "User resource for ${each.key}"
  account_ids = [boundary_account_password.user[each.value].id]
  scope_id    = boundary_scope.global.id
}

resource "boundary_auth_method_password" "password" {
  name        = "org_password_auth"
  description = "Password auth method for org"
  type        = "password"
  scope_id    = boundary_scope.global.id
}

resource "random_shuffle" "group" {
  input = [
    for o in boundary_user.user : o.id
  ]
  result_count = floor(length(var.users) / 4)
  count        = floor(length(var.users) / 2)
}

resource "boundary_account_password" "user" {
  for_each       = var.users
  name           = each.key
  description    = "User account for ${each.key}"
  login_name     = lower(each.key)
  password       = "rdprdprdp"
  auth_method_id = boundary_auth_method_password.password.id
}

resource "boundary_group" "group_global" {
  for_each = {
    for k, v in random_shuffle.group : k => v.id
  }
  name        = random_pet.group[each.key].id
  description = "Group: ${random_pet.group[each.key].id}"
  member_ids  = tolist(random_shuffle.group[each.key].result)
  scope_id    = boundary_scope.global.scope_id
}

resource "boundary_credential_store_vault" "ssh" {
  name        = "vault_store"
  description = "My first Vault credential store!"
  address     = var.vault_cluster_url  # change to Vault address
  token       = var.vault_client_token # change to valid Vault token
  scope_id    = boundary_scope.linux.id
  namespace   = "admin"
}



resource "boundary_credential_library_vault" "ssh" {
  name                = "vault_library"
  description         = "My first Vault credential library!"
  credential_store_id = boundary_credential_store_vault.ssh.id
  path                = "secret/ubuntu-secret"
  http_method         = "GET"
  credential_type     = "ssh_private_key"
}


resource "boundary_host_catalog_static" "ssh" {
  name        = "linux-hosts"
  description = "Linux Hosts (SSH)"
  scope_id    = boundary_scope.linux.id
}

resource "boundary_host_static" "rdp" {
  name            = var.rdp_target_hostname
  host_catalog_id = boundary_host_catalog_static.windows_hosts.id
  address         = var.rdp_target_address
}



resource "boundary_host_static" "ssh" {
  name            = var.ssh_target_hostname
  host_catalog_id = boundary_host_catalog_static.ssh.id
  address         = var.ssh_target_address
}

resource "boundary_host_set_static" "rdp" {
  type            = "static"
  name            = "rdp"
  host_catalog_id = boundary_host_catalog_static.windows_hosts.id

  host_ids = [
    boundary_host_static.rdp.id
  ]
}


# resource "boundary_worker" "controller_led" {
#   scope_id    = boundary_scope.global.scope_id
#   name        = "${var.iteration_name} worker 1"
#   description = "self managed worker with controller led auth"
# }

# resource "boundary_worker" "ingress_pki_worker" {
#   scope_id                    = "global"
#   name                        = "self-managed-worker-ingress"
#   worker_generated_auth_token = ""
# }

# # https://registry.terraform.io/providers/hashicorp/boundary/latest/docs/resources/storage_bucket#example-usage
# resource "boundary_storage_bucket" "aws_example" {
#   name            = "${var.iteration_name} storage bucket"
#   description     = "${var.iteration_name}'s session recording"
#   scope_id        = boundary_scope.global.id
#   plugin_name     = "aws"
#   bucket_name     = var.storage_bucket_name
#   attributes_json = jsonencode({ "region" = "us-west-1", "disable_credential_rotation" = true })

#   # recommended to pass in aws secrets using a file() or using environment variables
#   # the secrets below must be generated in aws by creating a aws iam user with programmatic access
#   secrets_json = jsonencode({
#     "access_key_id"     = "${var.access_key_id}",
#     "secret_access_key" = "${var.secret_access_key}"
#   })
#   worker_filter = "\"upstream\" in \"/tags/type\""

#   lifecycle {
#     ignore_changes = all
#   }

#   depends_on = [ 
#     time_sleep.wait_90_seconds,
#     aws_instance.upstream_ingress,
#     boundary_worker.downstream_egress,
#     boundary_worker.upstream_ingress
#    ]
# }

# https://registry.terraform.io/providers/hashicorp/boundary/latest/docs/resources/host_catalog_static#example-usage
resource "boundary_host_catalog_static" "linux_databases" {
  name        = "linux-databases"
  description = "Linux Databases"
  # type        = "static"
  scope_id = boundary_scope.linux.id
}

resource "boundary_host_catalog_static" "windows_hosts" {
  name        = "windows-hosts"
  description = "Windows Hosts (RDP)"
  # type        = "static"
  scope_id = boundary_scope.windows.id
}

resource "boundary_host_catalog_static" "windows_databases" {
  name        = "windows-databases"
  description = "Windows Databases"
  # type        = "static"
  scope_id = boundary_scope.windows.id
}

# https://registry.terraform.io/providers/hashicorp/boundary/latest/docs/resources/host_static#example-usage
resource "boundary_host_static" "unifi" {
  type        = "static"
  name        = "unifi"
  description = "Private unifi container"
  # DNS set via docker-compose
  address         = "unifi"
  host_catalog_id = boundary_host_catalog_static.ssh.id
}

# https://registry.terraform.io/providers/hashicorp/boundary/latest/docs/resources/host_set_static#example-usage
resource "boundary_host_set_static" "unifi" {
  type            = "static"
  name            = "unifi"
  description     = "Host set for unifi containers"
  host_catalog_id = boundary_host_catalog_static.ssh.id
  host_ids        = [boundary_host_static.unifi.id]
}

# https://registry.terraform.io/providers/hashicorp/boundary/latest/docs/resources/target#example-usage
resource "boundary_target" "unifi" {
  type                     = "tcp"
  address                  = var.ssh_target_address
  name                     = "unifi"
  description              = "Ubiquiti Unifi"
  scope_id                 = boundary_scope.linux.id
  session_connection_limit = -1
  session_max_seconds      = 86400
  default_port             = 8843
}

# https://registry.terraform.io/providers/hashicorp/boundary/latest/docs/resources/host_set_static#example-usage
resource "boundary_host_static" "mysql" {
  type            = "static"
  name            = "mysql"
  description     = "Private mysql container"
  address         = "mysql"
  host_catalog_id = boundary_host_catalog_static.linux_databases.id
}

resource "boundary_host_set_static" "mysql" {
  type            = "static"
  name            = "mysql"
  description     = "Host set for mysql containers"
  host_catalog_id = boundary_host_catalog_static.linux_databases.id
  host_ids        = [boundary_host_static.mysql.id]
}

# https://registry.terraform.io/providers/hashicorp/boundary/latest/docs/resources/target#example-usage
resource "boundary_target" "mysql" {
  type                     = "tcp"
  address                  = var.ssh_target_address
  name                     = "mysql"
  description              = "MySQL server"
  scope_id                 = boundary_scope.linux.id
  session_connection_limit = -1
  session_max_seconds      = 180
  default_port             = 3306
}

# https://registry.terraform.io/providers/hashicorp/boundary/latest/docs/resources/host_static#example-usage
resource "boundary_host_static" "postgres" {
  type        = "static"
  name        = "postgres"
  description = "Private postgres container"
  # DNS set via docker-compose
  address         = "postgres"
  host_catalog_id = boundary_host_catalog_static.linux_databases.id
}

# https://registry.terraform.io/providers/hashicorp/boundary/latest/docs/resources/host_set_static#example-usage
resource "boundary_host_set_static" "postgres" {
  type            = "static"
  name            = "postgres"
  description     = "Host set for postgres containers"
  host_catalog_id = boundary_host_catalog_static.linux_databases.id
  host_ids        = [boundary_host_static.postgres.id]
}

#https://registry.terraform.io/providers/hashicorp/boundary/latest/docs/resources/target#example-usage
resource "boundary_target" "postgres" {
  type                     = "tcp"
  address                  = var.ssh_target_address
  name                     = "postgres"
  description              = "Postgres server"
  scope_id                 = boundary_scope.linux.id
  session_connection_limit = -1
  session_max_seconds      = 180
  default_port             = 5432
}

resource "boundary_target" "rdp" {
  type                     = "tcp"
  name                     = "rdp"
  description              = "rdp server"
  scope_id                 = boundary_scope.windows.id
  session_connection_limit = -1
  session_max_seconds      = 300
  default_port             = 3389
  host_source_ids = [
    boundary_host_set_static.rdp.id
  ]
}

resource "boundary_host_static" "redis" {
  type            = "static"
  name            = "redis"
  description     = "Private redis container"
  address         = "redis"
  host_catalog_id = boundary_host_catalog_static.linux_databases.id
}

resource "boundary_host_set_static" "redis" {
  type            = "static"
  name            = "redis"
  description     = "Host set for redis containers"
  host_catalog_id = boundary_host_catalog_static.linux_databases.id
  host_ids        = [boundary_host_static.redis.id]
}

resource "boundary_target" "redis" {
  type                     = "tcp"
  address                  = var.ssh_target_address
  name                     = "redis"
  description              = "Redis server"
  scope_id                 = boundary_scope.linux.id
  session_connection_limit = -1
  session_max_seconds      = 180
  default_port             = 6379
}

resource "boundary_host_static" "cassandra" {
  type            = "static"
  name            = "cassandra"
  description     = "Private cassandra container"
  address         = "cassandra"
  host_catalog_id = boundary_host_catalog_static.linux_databases.id
}

resource "boundary_host_set_static" "cassandra" {
  type            = "static"
  name            = "cassandra"
  description     = "Host set for cassandra containers"
  host_catalog_id = boundary_host_catalog_static.linux_databases.id
  host_ids        = [boundary_host_static.cassandra.id]
}

resource "boundary_target" "cassandra" {
  type                     = "tcp"
  address                  = var.ssh_target_address
  name                     = "cassandra"
  description              = "Cassandra server"
  scope_id                 = boundary_scope.linux.id
  session_connection_limit = -1
  session_max_seconds      = 2
  default_port             = 7000
}

resource "boundary_host_set_static" "ssh" {
  type            = "static"
  name            = "ssh"
  description     = "Host set for ssh containers"
  host_catalog_id = boundary_host_catalog_static.ssh.id
  host_ids        = [boundary_host_static.ssh.id]
}

resource "boundary_target" "ssh" {
  type                     = "ssh"
  name                     = "ssh"
  address                  = var.ssh_target_address
  description              = "SSH server"
  scope_id                 = boundary_scope.linux.id
  session_connection_limit = -1
  session_max_seconds      = 300
  default_port             = 22

  ingress_worker_filter  = "\"upstream\" in \"/tags/type\""
  egress_worker_filter = "\"downstream\" in \"/tags/type\""

  # enable_session_recording = true
  # storage_bucket_id        = boundary_storage_bucket.aws_example.id

  injected_application_credential_source_ids = [
    boundary_credential_library_vault.ssh.id
  ]
}

resource "boundary_target" "aws_kmip_endpoint_https" {
  type                     = "tcp"
  name                     = "https://kmip.${data.aws_region.current.name}.amazonaws.com"
  address                  = "kmip.${data.aws_region.current.name}.amazonaws.com"
  description              = "AWS KMIP Endpoint via HTTPS in ${data.aws_region.current.name}"
  scope_id                 = boundary_scope.linux.id
  session_connection_limit = -1
  session_max_seconds      = 300
  default_port             = 443

  ingress_worker_filter  = "\"upstream\" in \"/tags/type\""
  egress_worker_filter = "\"downstream\" in \"/tags/type\""
  
}

resource "boundary_target" "aws_sts_endpoint_https" {
  type                     = "tcp"
  name                     = "https://sts.${data.aws_region.current.name}.amazonaws.com"
  address                  = "sts.${data.aws_region.current.name}.amazonaws.com"
  description              = "AWS STS Endpoint via HTTPS in ${data.aws_region.current.name}"
  scope_id                 = boundary_scope.linux.id
  session_connection_limit = -1
  session_max_seconds      = 300
  default_port             = 443

  ingress_worker_filter  = "\"upstream\" in \"/tags/type\""
  egress_worker_filter = "\"downstream\" in \"/tags/type\""
  
}

resource "boundary_target" "aws_s3_endpoint_https" {
  type                     = "tcp"
  name                     = "https://s3.${data.aws_region.current.name}.amazonaws.com"
  address                  = "s3.${data.aws_region.current.name}.amazonaws.com"
  description              = "AWS s3 Endpoint via HTTPS in ${data.aws_region.current.name}"
  scope_id                 = boundary_scope.linux.id
  session_connection_limit = -1
  session_max_seconds      = 300
  default_port             = 443

  ingress_worker_filter  = "\"upstream\" in \"/tags/type\""
  egress_worker_filter = "\"downstream\" in \"/tags/type\""
  
}

# https://registry.terraform.io/providers/hashicorp/boundary/latest/docs/resources/worker#example-usage
resource "boundary_worker" "upstream_ingress" {
  scope_id                    = boundary_scope.global.id
  name                        = "${var.iteration_name}-upstream-ingress"
  worker_generated_auth_token = ""
}

# https://registry.terraform.io/providers/hashicorp/boundary/latest/docs/resources/worker#example-usage
resource "boundary_worker" "downstream_egress" {
  scope_id                    = boundary_scope.global.id
  name                        = "${var.iteration_name}-downstream-egress"
  worker_generated_auth_token = ""
}