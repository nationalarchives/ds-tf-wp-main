resource "aws_s3_bucket_object" "nginx_conf" {
    bucket  = var.deployment_s3_bucket
    key     = "${var.service}/${var.nginx_conf_s3_key}/nginx.conf"
    source  = "scripts/nginx.conf"
    etag    = filemd5("scripts/nginx.conf")
}

resource "aws_s3_bucket_object" "admin_conf" {
    bucket  = var.deployment_s3_bucket
    key     = "${var.service}/${var.nginx_conf_s3_key}/wp_admin.conf"
    source  = "scripts/wp_admin.conf"
    etag    = filemd5("scripts/wp_admin.conf")
}

resource "aws_s3_bucket_object" "admin_subdomain_conf" {
    bucket  = var.deployment_s3_bucket
    key     = "${var.service}/${var.nginx_conf_s3_key}/wp_admin_subdomain.conf"
    source  = "scripts/wp_admin_subdomain.conf"
    etag    = filemd5("scripts/wp_admin_subdomain.conf")
}
