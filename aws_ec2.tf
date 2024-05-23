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

data "aws_ami" "windows" {
  most_recent = true
  owners      = ["self"]
  filter {
    name   = "name"
    values = ["msft-*"]
  }
}


resource "aws_vpc" "vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "demo-vpc-${local.owner_email}",
    User = "${local.owner_email}"
  }
}

resource "aws_subnet" "subnet" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = aws_vpc.vpc.cidr_block
  availability_zone       = data.aws_availability_zones.azs.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "demo-subnet-${local.owner_email}",
    User = "${local.owner_email}"
  }
}

resource "aws_internet_gateway" "gateway" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "demo-ig-${local.owner_email}"
    User = "${local.owner_email}"
  }
}

resource "aws_route_table" "route_table" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "demo-rt-${local.owner_email}"
    User = "${local.owner_email}"
  }
}

resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gateway.id
}

resource "aws_route_table_association" "subnet_assocs" {
  route_table_id = aws_route_table.route_table.id
  subnet_id      = aws_subnet.subnet.id
}


resource "aws_security_group" "boundary" {
  vpc_id = aws_vpc.vpc.id
  name = "demo-sg-${local.owner_email}"

  tags = {
    Name = "demo-sg-${local.owner_email}"
    User = "${local.owner_email}"
  }
}

resource "aws_security_group" "dba" {
  vpc_id = aws_vpc.vpc.id
  name = "demo-sg-${local.owner_email}-dba"

  tags = {
    Name = "demo-sg-${local.owner_email}-dba"
    User = "${local.owner_email}"
  }
}

resource "aws_security_group" "plex" {
  vpc_id = aws_vpc.vpc.id
  name = "demo-sg-${local.owner_email}-plex"

  tags = {
    Name = "demo-sg-${local.owner_email}-plex"
    User = "${local.owner_email}"
  }
}

resource "aws_security_group" "rdp" {
  vpc_id = aws_vpc.vpc.id
  name = "demo-sg-${local.owner_email}-rdp"

  tags = {
    Name = "demo-sg-${local.owner_email}-rdp"
    User = "${local.owner_email}"
  }
}

resource "aws_security_group" "ssh" {
  vpc_id = aws_vpc.vpc.id
  name = "demo-sg-${local.owner_email}-ssh"

  tags = {
    Name = "demo-sg-${local.owner_email}-ssh"
    User = "${local.owner_email}"
  }
}

resource "aws_security_group" "unifi" {
  vpc_id = aws_vpc.vpc.id
  name = "demo-sg-${local.owner_email}-unifi"

  tags = {
    Name = "demo-sg-${local.owner_email}-unifi"
    User = "${local.owner_email}"
  }
}

resource "aws_security_group_rule" "unifi_https_in" {
  type              = "ingress"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 443
  to_port           = 443
  security_group_id = aws_security_group.unifi.id
}

resource "aws_security_group_rule" "unifi_https_devices" {
  type              = "ingress"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 8080
  to_port           = 8080
  security_group_id = aws_security_group.unifi.id
}

resource "aws_security_group_rule" "unifi_https_alt" {
  type              = "ingress"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 8843
  to_port           = 8843
  security_group_id = aws_security_group.unifi.id
}

resource "aws_security_group_rule" "security_group_all_out" {
  type              = "ingress"
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  to_port           = 65535
  security_group_id = aws_security_group.boundary.id
}

resource "aws_security_group_rule" "security_group_ssh_in" {
  type              = "egress"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 22
  to_port           = 22
  security_group_id = aws_security_group.ssh.id
}

resource "aws_security_group_rule" "security_group_boundary_out" {
  type              = "egress"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 9200
  to_port           = 9204
  security_group_id = aws_security_group.boundary.id
}

resource "aws_security_group_rule" "security_group_cassandra_in" {
  type              = "egress"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 9042
  to_port           = 9042
  security_group_id = aws_security_group.dba.id
}


resource "aws_security_group_rule" "security_group_http_in" {
  type              = "egress"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 80
  to_port           = 80
  security_group_id = aws_security_group.boundary.id
}

resource "aws_security_group_rule" "security_group_https_in" {
  type              = "egress"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 443
  to_port           = 443
  security_group_id = aws_security_group.boundary.id
}

resource "aws_security_group_rule" "security_group_mysql_in" {
  type              = "egress"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 3306
  to_port           = 3306
  security_group_id = aws_security_group.dba.id
}

resource "aws_security_group_rule" "security_group_plex_in" {
  type              = "egress"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 32400
  to_port           = 32400
  security_group_id = aws_security_group.plex.id
}

resource "aws_security_group_rule" "security_group_postgres_in" {
  type              = "egress"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 5432
  to_port           = 5432
  security_group_id = aws_security_group.dba.id
}

resource "aws_security_group_rule" "security_group_rdp_in" {
  type              = "egress"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 3389
  to_port           = 3389
  security_group_id = aws_security_group.rdp.id
}

resource "aws_security_group_rule" "security_group_redis_in" {
  type              = "egress"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 6379
  to_port           = 6379
  security_group_id = aws_security_group.dba.id
}

resource "aws_instance" "boundary_target_rdp" {
  ami           = data.aws_ami.windows.id
  instance_type = "t3.medium"
  subnet_id     = aws_subnet.subnet.id
  key_name      = aws_key_pair.demo_ec2_ssh_key_pair.id
  vpc_security_group_ids = [
    aws_security_group.boundary.id,
    aws_security_group.rdp.id
  ]

  tags = merge({
    "Name" : "${random_pet.example.id}-target-rdp"
    "User" : local.owner_email
  })


  user_data = templatefile("${path.module}/scripts/boundary-target-user-data.ps1", {
    log_path                            = "/var/log"
  })

  lifecycle {
    ignore_changes = all
  }
}

resource "aws_instance" "boundary_target_ssh" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.medium"
  subnet_id     = aws_subnet.subnet.id
  key_name      = aws_key_pair.demo_ec2_ssh_key_pair.id
  vpc_security_group_ids = [
    aws_security_group.boundary.id,
    aws_security_group.dba.id,
    aws_security_group.plex.id,
    aws_security_group.ssh.id,
    aws_security_group.unifi.id
  ]


  tags = merge({
    "Name" : "${random_pet.example.id}-target-ssh"
    "User" : local.owner_email
  })

  user_data = templatefile("${path.module}/scripts/boundary-target-user-data.sh", {
    log_path = "/var/log"
  })

  lifecycle {
    ignore_changes = all
  }

}
