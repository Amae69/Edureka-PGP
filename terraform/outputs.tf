output "app_public_ip" {
  description = "Public IP of the App Server"
  value       = aws_instance.app_server.public_ip
}

output "monitoring_public_ip" {
  description = "Public IP of the Monitoring Server"
  value       = aws_instance.monitoring_server.public_ip
}
