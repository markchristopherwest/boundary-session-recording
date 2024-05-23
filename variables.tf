data "aws_caller_identity" "current" {}

locals {
  owner_email             = split(":", data.aws_caller_identity.current.user_id)[1]
  instance_tags = [
    {
      "${random_id.foo_key.dec}" = "test",
      "${random_id.qux_key.dec}" = "true",
    },
    {
      "${random_id.foo_key.dec}" = "prod",
      "${random_id.bar_key.dec}" = "true",
      "${random_id.qux_key.dec}" = "true",
    },
    {
      "${random_id.bar_key.dec}" = "true",
      "${random_id.qux_key.dec}" = "true",
    },
    {
      "${random_id.bar_key.dec}" = "true",
      "${random_id.baz_key.dec}" = "true",
      "${random_id.qux_key.dec}" = "true",
    },
    {
      "${random_id.baz_key.dec}" = "true",
      "${random_id.qux_key.dec}" = "true",
    },
  ]

}

resource "random_id" "foo_key" {
  prefix      = "foo"
  byte_length = 4
}

resource "random_id" "qux_key" {
  prefix      = "qux"
  byte_length = 4
}

resource "random_id" "bar_key" {
  prefix      = "bar"
  byte_length = 4
}

resource "random_id" "baz_key" {
  prefix      = "baz"
  byte_length = 4
}

variable "aws_region" {
  type    = list(string)
  default = ["us-west"]
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

variable "boundary_version" {
  type    = string
  default = "0.14.3"
}

variable "boundary_path_auth" {
  type    = string
  default = "/home/boundary/boundary-auth/"
}

variable "boundary_path_recording" {
  type    = string
  default = "/home/boundary/boundary-session-recording/capture/"
}

variable "iam_user_count" {
  default = 2
}

variable "ssh_key_pair_prefix" {
  default = "boundary-aws-demo-stack-ssh-keypair"
}
