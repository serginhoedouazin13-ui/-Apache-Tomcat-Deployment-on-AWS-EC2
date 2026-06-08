output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.tomcat.id
}

output "public_ip" {
  description = "Public IP of Tomcat server"
  value       = aws_instance.tomcat.public_ip
}

output "tomcat_url" {
  description = "Tomcat URL"
  value       = "http://:8080"
}
