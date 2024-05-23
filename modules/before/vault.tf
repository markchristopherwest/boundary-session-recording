resource "vault_policy" "general" {
  # namespace = "admin"
  name = "general"

  policy = <<EOT
# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

path "auth/token/lookup-self" {
  capabilities = ["read"]
}

path "auth/token/renew-self" {
  capabilities = ["update"]
}

path "auth/token/revoke-self" {
  capabilities = ["update"]
}

path "sys/leases/renew" {
  capabilities = ["update"]
}

path "sys/leases/revoke" {
  capabilities = ["update"]
}

path "sys/capabilities-self" {
  capabilities = ["update"]
}

EOT
}

resource "vault_policy" "ubuntu_secret" {
  # namespace = "admin"
  name = "ubuntu-secret"
  # namespace = "admin"
  policy = <<EOT
# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

path "kvv1/secret/data/ubuntu-secret" {
  capabilities = ["read"]
}
path "kvv1/data/ubuntu-secret" {
  capabilities = ["read"]
}
path "secret/data/ubuntu-secret" {
  capabilities = ["read"]
}
path "secret/ubuntu-secret" {
  capabilities = ["read", "update"]
}
EOT
}

resource "vault_mount" "ssh_mount" {
  path        = "ssh-client-ubuntu"
  type        = "ssh"
  description = "SSH Mount for Ubuntu"
}

resource "vault_ssh_secret_backend_role" "ssh_role" {
  name                    = "boundary-client"
  backend                 = vault_mount.ssh_mount.path
  key_type                = "ca"
  allow_host_certificates = true
  allow_user_certificates = true
  default_user            = "ubuntu"
  ttl                     = "2m0s"

  default_extensions = {
    permit-pty = ""
  }
  allowed_users      = "*"
  allowed_extensions = "*"
}

resource "vault_ssh_secret_backend_ca" "ssh_backend" {
  backend              = vault_mount.ssh_mount.path
  generate_signing_key = true

}

resource "vault_token" "example" {
  policies = [
    vault_policy.ubuntu_secret.name,
    vault_policy.general.name
  ]
  no_default_policy = true
  no_parent         = true
  period            = "20m"
  renewable         = true
  metadata = {
    "purpose" = "dynamic-credential-stores"
  }
  depends_on = [vault_policy.ubuntu_secret]
}

resource "vault_mount" "kvv1" {
  path        = "secret"
  type        = "kv"
  options     = { version = "1" }
  description = "KV Version 1 secret engine mount"
}

resource "vault_kv_secret" "secret" {
  path = "${vault_mount.kvv1.path}/ubuntu-secret"
  data_json = jsonencode(
    {
      username    = "ubuntu",
      private_key = var.private_key
    }
  )
}
