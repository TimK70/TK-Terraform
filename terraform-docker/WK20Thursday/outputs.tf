output "sg_id" {
  value = aws_security_group.allow_http.id
}

output "sg_name" {
  value = aws_security_group.allow_http.name
  sensitive = true
}