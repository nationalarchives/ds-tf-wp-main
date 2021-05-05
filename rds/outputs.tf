output "website_main_rds_identifier" {
    value = aws_db_instance.main.identifier
}

output "website_rds_route53_record_name" {
    value = aws_route53_record.db.name
}

output "website_rds_sg_id" {
    value = aws_security_group.website_db.id
}
