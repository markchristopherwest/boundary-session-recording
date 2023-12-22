resource "hcp_hvn" "example" {
  hvn_id         = var.iteration_name
  cloud_provider = "aws"
  region         = "us-west-2"
  cidr_block     = "172.25.16.0/20"
}

resource "hcp_vault_cluster" "example" {
  cluster_id      = var.iteration_name
  hvn_id          = hcp_hvn.example.hvn_id
  tier            = "plus_small"
  public_endpoint = true

  lifecycle {
    prevent_destroy = false
  }

}

resource "hcp_boundary_cluster" "example" {
  cluster_id = var.iteration_name
  username   = "admin"
  password   = var.password
  tier       = "Plus"

}

resource "hcp_vault_cluster_admin_token" "example" {
  cluster_id = hcp_vault_cluster.example.cluster_id
}
