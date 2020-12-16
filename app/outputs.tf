output "website_public_sg_id" {
    value = aws_security_group.website_public.id
}

output "website_app_sg_id" {
    value = aws_security_group.website_app.id
}

output "website_efs_sg_id" {
    value = aws_security_group.website_efs.id
}

output "website_public_lb_dns_name" {
    value = aws_lb.website_public.dns_name
}

output "website_public_lb_zone_id" {
    value = aws_lb.website_public.zone_id
}
