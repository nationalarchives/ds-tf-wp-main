output "main_public_sg_id" {
    value = aws_security_group.main_public.id
}

output "main_app_sg_id" {
    value = aws_security_group.main_app.id
}
