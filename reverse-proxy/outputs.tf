output "reverse_proxy_app_sg_id" {
    value = aws_security_group.rp.id
}

output "efs_id" {
    value = aws_efs_file_system.rp_efs.id
}
