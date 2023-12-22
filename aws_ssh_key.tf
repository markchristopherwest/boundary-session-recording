resource "tls_private_key" "demo_ec2_ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "random_id" "demo_ec2_ssh_key_pair_name" {
  prefix      = var.ssh_key_pair_prefix
  byte_length = 4
}

resource "aws_key_pair" "demo_ec2_ssh_key_pair" {
  key_name   = random_id.demo_ec2_ssh_key_pair_name.dec
  public_key = tls_private_key.demo_ec2_ssh_key.public_key_openssh
}
