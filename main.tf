# ------------------------
# VPC
# ------------------------
resource "aws_vpc" "php_test" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = var.vpc_php_name
  }
}

# ------------------------
# SUBNETS
# ------------------------
resource "aws_subnet" "php_public_subnet" {
  vpc_id                  = aws_vpc.php_test.id
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

resource "aws_internet_gateway" "php_igw" {
  vpc_id = aws_vpc.php_test.id

  tags = {
    Name = "${var.vpc_php_name}-igw"
  }
}

# ------------------------
# ROUTE TABLE
# ------------------------

resource "aws_route_table" "php_public_rt" {
  vpc_id = aws_vpc.php_test.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.php_igw.id
  }

  tags = {
    Name = "${var.vpc_php_name}-public-rt"
  }
}

# ------------------------
# ROUTE TABLE ASSOCIATION
# ------------------------

resource "aws_route_table_association" "php_public_rt_assoc" {
  subnet_id      = aws_subnet.php_public_subnet.id
  route_table_id = aws_route_table.php_public_rt.id
}

# ------------------------
# EC2 INSTANCE
# ------------------------

resource "aws_instance" "php_ec2" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.php_public_subnet.id
  key_name                    = var.key_name
  associate_public_ip_address = true

  vpc_security_group_ids = [aws_security_group.php_sg.id]

  tags = {
    Name = var.ec2_name
  }
}

resource "aws_security_group" "php_sg" {
  name        = "${var.ec2_name}-sg"
  description = "Allow SSH and HTTP"
  vpc_id      = aws_vpc.php_test.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
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