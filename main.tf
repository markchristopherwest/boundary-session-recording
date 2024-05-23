
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.28.0"

    }
    hcp = {
      source  = "hashicorp/hcp"
      version = ">= 0.77.0"

    }
    boundary = {
      source  = "hashicorp/boundary"
      version = ">= 1.1.10"
    }
    vault = {
      source  = "hashicorp/vault"
      version = ">= 3.23.0"
    }
  }
}

data "external" "whoami" {
  program = ["${path.module}/externals/external-whoami.sh"]
}

provider "aws" {
  region = "us-west-1"
}

resource "random_pet" "example" {}

module "before" {
  source         = "./modules/before"
  iteration_name = random_pet.example.id
  password       = data.external.whoami.result["local_user"]
  private_key    = tls_private_key.demo_ec2_ssh_key.private_key_pem

}

provider "boundary" {
  addr                   = module.before.addr_boundary
  auth_method_login_name = module.before.boundary_user
  auth_method_password   = data.external.whoami.result["local_user"]
}

provider "vault" {
  address = module.before.addr_vault
  token   = module.before.vault_token_admin
}

# module "after" {
#   source         = "./modules/after"
#   boundary_cluster_url = module.before.addr_boundary
#   iteration_name = random_pet.example.id

#   controller_url  = module.before.addr_boundary

#   storage_bucket_name = aws_s3_bucket.storage_bucket.bucket

#   rdp_target_hostname = aws_instance.boundary_target_rdp.public_dns
#   rdp_target_address  = aws_instance.boundary_target_rdp.public_ip

#   ssh_target_hostname = aws_instance.boundary_target_ssh.public_dns
#   ssh_target_address  = aws_instance.boundary_target_ssh.public_ip

#   vault_cluster_url  = module.before.addr_vault
#   vault_client_token = module.before.vault_token_boundary

#   vault_secret_path = module.before.vault_secret_path

#   hcp_vault_cluster_admin_token = module.before.vault_token_admin

#   private_key = tls_private_key.demo_ec2_ssh_key.private_key_pem

#   access_key_id     = aws_iam_access_key.storage_user_key.id
#   secret_access_key = aws_iam_access_key.storage_user_key.secret

#   vpc_security_group_ids = [
#     aws_security_group.boundary.id,
#     aws_security_group.dba.id,
#     aws_security_group.plex.id,
#     aws_security_group.ssh.id
#   ]

#   vpc_subnet_id = aws_subnet.subnet.id
#   ec2_ssh_key   = aws_key_pair.demo_ec2_ssh_key_pair.id

#   depends_on = [module.before]

# }

# output "your_worker_downstream" {
#   value = module.after.your_worker_downstream
# }

# output "your_worker_upstream" {
#   value = module.after.your_worker_upstream
# }
