output "ec2_ip" {
  value = aws_instance.ec2.private_ip
}
