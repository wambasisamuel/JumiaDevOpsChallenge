output "app_instance" {
  description = "Public IP of Application EC2 Instance"
  value       = aws_instance.application.public_ip

}

output "db_instance" {
  description = "Pubblic IP of Database EC2 Instance"
  value       = aws_instance.database.public_ip
}

output "lb_instance" {
  description = "Public IP of Load Balancer EC2 Instance"
  value       = aws_instance.load_balancer.public_ip
}
