variable "vpc_cidr" {
  description = "CIDR block for php-test"
  type        = string
  default     = "10.15.0.0/16"
}

variable "vpc_php_name" {
  description = "Name tag for the VPC"
  type        = string
}

variable "sub_cidr" {
  description = "CIDR block for php-test-subnet"
  type        = string
  default     = "10.15.1.0/24"
}

variable "availability_zone" {
  description = "availability_zone"
  type        = string
  default     = "ap-south-1a"
}

variable "sub_name" {
  description = "Name tag for the subnet"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for the EC2 instance"
  type        = string
  default     = "ami-00305d2fa3c93abfc"
}

variable "instance_type" {
  description = "Instance type for EC2"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "Name of the existing EC2 Key Pair"
  type        = string
}

variable "ec2_name" {
  description = "Name tag for the EC2 instance"
  type        = string
}