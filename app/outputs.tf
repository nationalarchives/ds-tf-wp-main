output "website_app_sg_id" {
    value = aws_security_group.website_app.id
}

output "website_efs_sg_id" {
    value = aws_security_group.website_efs.id
}

output "website_internal_lb_dns_name" {
    value = aws_lb.website_internal.dns_name
}

output "website_internal_lb_zone_id" {
    value = aws_lb.website_internal.zone_id
}

output "website_internal_lb_arn_suffix" {
    value = aws_lb.website_internal.arn_suffix
}

output "website_internal_lb_target_group_arn_suffix" {
    value = aws_lb_target_group.website_internal.arn_suffix
}

output "efs_id" {
    value = aws_efs_file_system.website.id
}

output "efs_mount_target" {
    value = aws_efs_file_system.website.dns_name
}

output "efs_mount_dr" {
    value = var.efs_mount_dir
}

output "website_autoscaling_group_name" {
    value = aws_autoscaling_group.website.name
}

output "website_autoscaling_up_policy_arn" {
    value = aws_autoscaling_policy.website_up_policy.arn
}

output "website_autoscaling_down_policy_arn" {
    value = aws_autoscaling_policy.website_down_policy.arn
}
