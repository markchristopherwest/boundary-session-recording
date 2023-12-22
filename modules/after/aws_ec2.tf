data "aws_caller_identity" "current" {}
locals {
  owner_email = split(":", data.aws_caller_identity.current.user_id)[1]
}
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region#example-usage
data "aws_region" "current" {}

data "aws_availability_zones" "azs" {}

data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "downstream_egress" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  subnet_id              = var.vpc_subnet_id
  key_name               = var.ec2_ssh_key
  vpc_security_group_ids = var.vpc_security_group_ids

  tags = merge({
    "Name" : "${var.iteration_name}-worker-downstream-egress"
    "User" : local.owner_email
  })
  user_data = templatefile("${path.module}/scripts/boundary-worker-egress-user-data.sh", {
    boundary_activation_token           = boundary_worker.downstream_egress.controller_generated_activation_token
    boundary_controller_port      = "9200"
    boundary_cluster_id           = "${split(".", split("//", var.controller_url)[1])[0]}"
    boundary_path_auth            = var.boundary_path_auth
    boundary_path_captrure        = var.boundary_path_recording
    boundary_worker_address       = "0.0.0.0"
    boundary_worker_upstream_host = "${aws_instance.upstream_ingress.public_ip}"
    boundary_worker_upstream_port = "9202"

    boundary_worker_port                = "9202"
    boundary_worker_purpose       = "proxy"

    boundary_worker_tags = merge({
      "Name" : "${var.iteration_name}-worker-downstream-egress"
      "User" : local.owner_email
    })

    iteration_name = var.iteration_name
    log_path = "/var/log"
  })
  root_block_device {
    volume_type = "gp3"
  }
  lifecycle {
    ignore_changes = all
  }
}

resource "aws_instance" "upstream_ingress" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  subnet_id              = var.vpc_subnet_id
  key_name               = var.ec2_ssh_key
  vpc_security_group_ids = var.vpc_security_group_ids
  tags = merge({
    "Name" : "${var.iteration_name}-worker-upstream-ingress"
    "User" : local.owner_email
  })
  user_data = templatefile("${path.module}/scripts/boundary-worker-ingress-user-data.sh", {
    boundary_activation_token           = boundary_worker.upstream_ingress.controller_generated_activation_token
    boundary_path_auth                  = var.boundary_path_auth
    boundary_path_captrure              = var.boundary_path_recording
    boundary_cluster_id                 = "${split(".", split("//", var.controller_url)[1])[0]}"
    boundary_worker_address             = "0.0.0.0"
    boundary_worker_port                = "9202"
    boundary_worker_purpose             = "proxy"
    boundary_worker_tag                 = "dev"
    boundary_worker_tags = merge({
      "Name" : "${var.iteration_name}-worker-downstream-egress"
      "User" : local.owner_email
    })
    
    iteration_name = var.iteration_name
    log_path                            = "/var/log"
  })
  root_block_device {
    volume_type = "gp3"
  }
  lifecycle {
    ignore_changes = all
  }
  
}

resource "time_sleep" "wait_90_seconds" {
  depends_on = [
    aws_instance.downstream_egress,
    aws_instance.upstream_ingress
    ]

  create_duration = "90s"
}