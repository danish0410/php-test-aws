output "nginx_ec2_public_ip" {
  value       = aws_instance.nginx_ec2.public_ip
  description = "Public IP of the nginx EC2 instance"
}