output "addr_boundary" {
  value       = hcp_boundary_cluster.example.cluster_url
  description = "Boundary Cluster URL"
}

output "addr_vault" {
  value       = hcp_vault_cluster.example.vault_public_endpoint_url
  description = "Vault Cluster URL"
}

output "boundary_user" {
  value       = hcp_boundary_cluster.example.username
  description = "Boundary Admin Username"
}

output "boundary_pass" {
  value       = hcp_boundary_cluster.example.password
  description = "Boundary Admin Password"
}

output "vault_secret_path" {
  value       = vault_kv_secret.secret.path
  description = "Vault Secret Path"
}

output "vault_token_admin" {
  value       = hcp_vault_cluster_admin_token.example.token
  description = "Vault Token for Administration"
}

output "vault_token_boundary" {
  value       = vault_token.example.client_token
  description = "Vault Token for Boundary"
}
