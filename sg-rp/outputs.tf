output "lb_sg_id" {
    value = aws_security_group.rp_lb.id
}

output "lb_sg_name" {
    value = aws_security_group.rp_lb.name
}

output "rp_sg_id" {
    value = aws_security_group.rp.id
}

output "rp_sg_name" {
    value = aws_security_group.rp.name
}

output "rp_efs_sg_id" {
    value = aws_security_group.rp_efs.id
}

output "rp_efs_sg_name" {
    value = aws_security_group.rp_efs.name
}
