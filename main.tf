provider "aws" {
  region = "ap-south-1"
}

# ------------------------
# VPC
# ------------------------
resource "aws_vpc" "nginx_test" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = var.vpc_name
  }
}

# ------------------------
# SUBNETS
# ------------------------
resource "aws_subnet" "nginx_public_subnet" {
  vpc_id                  = aws_vpc.nginx_test.id
  cidr_block              = var.sub_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name = var.sub_name
  }
}

# ------------------------
# INTERNET GATEWAY
# ------------------------

resource "aws_internet_gateway" "nginx_igw" {
  vpc_id = aws_vpc.nginx_test.id

  tags = {
    Name = "${var.vpc_name}-igw"
  }
}

# ------------------------
# ROUTE TABLE
# ------------------------

resource "aws_route_table" "nginx_public_rt" {
  vpc_id = aws_vpc.nginx_test.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.nginx_igw.id
  }

  tags = {
    Name = "${var.vpc_name}-public-rt"
  }
}

# ------------------------
# ROUTE TABLE ASSOCIATION
# ------------------------

resource "aws_route_table_association" "nginx_public_rt_assoc" {
  subnet_id      = aws_subnet.nginx_public_subnet.id
  route_table_id = aws_route_table.nginx_public_rt.id
}

# ------------------------
# EC2 INSTANCE
# ------------------------

resource "aws_instance" "nginx_ec2" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.nginx_public_subnet.id
  key_name                    = var.key_name
  associate_public_ip_address = true

  vpc_security_group_ids = [aws_security_group.nginx_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              sudo apt update
              sudo apt upgrade -y

              sudo apt install -y software-properties-common
              sudo add-apt-repository --yes --update ppa:ansible/ansible
              sudo apt install -y ansible
              sudo apt install -y vim git lsof

              # Wait for EBS volume to be attached
              sleep 10

              # Format and mount EBS volume
              if ! grep -qs '/mnt/data' /proc/mounts; then
                sudo mkfs -t ext4 /dev/xvdf
                sudo mkdir -p /mnt/data
                sudo mount /dev/xvdf /mnt/data
                echo '/dev/xvdf /mnt/data ext4 defaults,nofail 0 2' | sudo tee -a /etc/fstab
              fi
              EOF

  tags = {
    Name = var.ec2_name
  }
}

resource "aws_security_group" "nginx_sg" {
  name        = "${var.ec2_name}-sg"
  description = "Allow SSH, HTTP, and HTTPS only from your IP"
  vpc_id      = aws_vpc.nginx_test.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["45.119.28.79/32"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["45.119.28.79/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.ec2_name}-sg"
  }
}

resource "aws_s3_bucket" "nginx_test" {
  bucket = "nginx-test-bucket-thanigai2808"

  tags = {
    Name = "nginx-bucket"
  }
}

resource "aws_ebs_volume" "php_data_disk" {
  availability_zone = var.availability_zone
  size              = 10
  type              = "gp3"

  tags = {
    Name = "${var.ec2_name}-data-disk"
  }
}

resource "aws_volume_attachment" "php_data_disk_attachment" {
  device_name  = "/dev/xvdf"
  volume_id    = aws_ebs_volume.php_data_disk.id
  instance_id  = aws_instance.nginx_ec2.id
  force_detach = true
}