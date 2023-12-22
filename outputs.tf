output "iam_user_names" {
  value = aws_iam_user.user.*.name
}

output "iam_user_arns" {
  value = aws_iam_user.user.*.arn
}

output "iam_access_key_ids" {
  value     = aws_iam_access_key.user_initial_key.*.id
  sensitive = true
}

output "instance_ssh_private_key" {
  value     = tls_private_key.demo_ec2_ssh_key.private_key_pem
  sensitive = true
}

output "instance_ssh_public_key" {
  value = tls_private_key.demo_ec2_ssh_key.public_key_openssh
}

output "hcp_boundary_cluster_username" {
  value = data.external.whoami.result["local_user"]
}

output "hcp_boundary_cluster_password" {
  value = random_pet.example.id
}

output "bucket_name" {
  value = aws_s3_bucket.storage_bucket.id
}

output "storage_user_access_key_id" {
  value     = aws_iam_access_key.storage_user_key.id
  sensitive = true
}

output "storage_user_secret_access_key" {
  value     = aws_iam_access_key.storage_user_key.secret
  sensitive = true
}

output "your_hcp_boundary_instance" {
  value = module.before.addr_boundary
}

output "your_hcp_boundary_user" {
  value = module.before.boundary_user
}

output "your_hcp_boundary_pass" {
  value     = module.before.boundary_pass
  sensitive = true
}

output "your_hcp_vault_instance" {
  value = module.before.addr_vault
}

output "your_target_rdp_instance" {
  value = aws_instance.boundary_target_rdp.public_ip
}

output "your_target_ssh_instance" {
  value = aws_instance.boundary_target_ssh.public_ip
}
