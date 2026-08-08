########################################
# Default VPC & Subnet
########################################

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

########################################
# Key Pair
########################################

resource "aws_key_pair" "key" {
  key_name   = var.key_pair_name
  public_key = file(var.public_key_path)
}

########################################
# Security Group
########################################

resource "aws_security_group" "main_sg" {

  name        = "pulseguard-sg"
  description = "Security Group for PulseGuard Infrastructure"
  vpc_id      = data.aws_vpc.default.id

  ###################################
  # SSH
  ###################################

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  ###################################
  # Jenkins
  ###################################

  ingress {
    description = "Jenkins"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  ###################################
  # Grafana
  ###################################

  ingress {
    description = "Grafana"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  ###################################
  # Prometheus
  ###################################

  ingress {
    description = "Prometheus"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  ###################################
  # HTTP
  ###################################

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  ###################################
  # HTTPS
  ###################################

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  ###################################
  # Kubernetes API Server
  ###################################

  ingress {
    description = "Kubernetes API"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    self        = true
  }

  ###################################
  # etcd
  ###################################

  ingress {
    description = "etcd"
    from_port   = 2379
    to_port     = 2380
    protocol    = "tcp"
    self        = true
  }

  ###################################
  # Kubelet
  ###################################

  ingress {
    description = "Kubelet"
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    self        = true
  }

  ###################################
  # kube-controller-manager
  ###################################

  ingress {
    description = "Controller Manager"
    from_port   = 10257
    to_port     = 10257
    protocol    = "tcp"
    self        = true
  }

  ###################################
  # kube-scheduler
  ###################################

  ingress {
    description = "Scheduler"
    from_port   = 10259
    to_port     = 10259
    protocol    = "tcp"
    self        = true
  }

  ###################################
  # NodePort Services
  ###################################

  ingress {
    description = "NodePort Services"
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    self        = true
  }

  ###################################
  # Outbound
  ###################################

  egress {
    description = "Allow All Outbound Traffic"

    from_port   = 0
    to_port     = 0
    protocol    = "-1"

    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "pulseguard-sg"
  }
}

########################################
# EC2 Instances
########################################

resource "aws_instance" "servers" {

  for_each = var.instance_names

  ami           = var.ami_id
  instance_type = var.instance_types[each.key]

  subnet_id = data.aws_subnets.default.ids[0]

  vpc_security_group_ids = [
    aws_security_group.main_sg.id
  ]

  key_name = aws_key_pair.key.key_name

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = "gp3"
  }

  tags = {
    Name = each.value
  }
}

########################################
# Amazon ECR
########################################

resource "aws_ecr_repository" "repository" {

  name                 = var.ecr_repository_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = var.ecr_repository_name
  }
}