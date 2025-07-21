output "php_ec2_public_ip" {
  value       = aws_instance.php_ec2.public_ip
  description = "Public IP of the PHP EC2 instance"
}