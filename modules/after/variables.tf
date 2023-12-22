variable "boundary_cluster_url" {
  type = string
  # default = "http://localhost:9200"
}

variable "vault_cluster_url" {
  type = string
  # default = "http://localhost:8200"
}

variable "vault_client_token" {
  type    = string
  default = "foo"
}

variable "vault_secret_path" {
  type    = string
  default = "secret/foo"
}

variable "hcp_vault_cluster_admin_token" {
  type    = string
  default = "bar"
}

variable "iteration_name" {
  type    = string
  default = "bar"
}

variable "storage_bucket_name" {
  type    = string
  default = "foo"
}

variable "rdp_target_hostname" {
  type = string
  #   default = "localhost"
}

variable "rdp_target_address" {
  type = string
  #   default = "127.0.0.1"
}

variable "ssh_target_hostname" {
  type = string
  #   default = "localhost"
}

variable "ssh_target_address" {
  type = string
  #   default = "127.0.0.1"
}

variable "worker_auth_token" {
  type    = string
  default = "foo"
}



variable "boundary_port_controller" {
  type    = string
  default = "9200"
}

variable "boundary_port_cluster" {
  type    = string
  default = "9201"
}

variable "boundary_port_worker" {
  type    = string
  default = "9202"
}

variable "controller_url" {
  type = string
  # default = "http://localhost:9202"
}

variable "private_key" {
  type    = string
  default = "foo"
}

variable "access_key_id" {
  type = string
}

variable "secret_access_key" {
  type = string
}

variable "vpc_security_group_ids" {
  type = list(any)
}

variable "vpc_subnet_id" {
  type = string
}

variable "ec2_ssh_key" {
  type = string
}


# variable "boundary_activation_token_downstream_egress" {
#   type = string
# }

# variable "boundary_activation_token_upstreamm_ingress" {
#   type = string
# }

variable "boundary_path_auth" {
  type    = string
  default = "/home/boundary/boundary-auth/"
}

variable "boundary_path_recording" {
  type    = string
  default = "/home/boundary/boundary-session-recording/capture/"
}
