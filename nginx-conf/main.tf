resource "aws_s3_bucket_object" "nginx_conf" {
    bucket = var.deployment_s3_bucket
    key    = "${var.service}/${var.nginx_conf_s3_key}/nginx.conf"
    source = templatefile("${path.module}/scripts/nginx.conf", {
        environment      = var.environment,
        set_real_ip_from = var.set_real_ip_from,
        resolver         = var.resolver,
        ups_website      = var.ups_website,
        ups_appslb       = var.ups_appslb,
        ups_legacy_apps  = var.ups_legacy_apps
    })
    etag   = filemd5("${path.module}/scripts/nginx.conf")
}

resource "aws_s3_bucket_object" "admin_conf" {
    bucket = var.deployment_s3_bucket
    key    = "${var.service}/${var.nginx_conf_s3_key}/wp_admin.conf"
    source = templatefile("${path.module}/scripts/wp_admin.conf", {
        environment      = var.environment,
        set_real_ip_from = var.set_real_ip_from,
        resolver         = var.resolver
    })
    etag   = filemd5("${path.module}/scripts/wp_admin.conf")
}

resource "aws_s3_bucket_object" "admin_subdomain_conf" {
    bucket = var.deployment_s3_bucket
    key    = "${var.service}/${var.nginx_conf_s3_key}/wp_admin_subdomain.conf"
    source = templatefile("${path.module}/scripts/wp_admin_subdomain.conf", {
        environment      = var.environment,
        set_real_ip_from = var.set_real_ip_from,
        resolver         = var.resolver
    })
    etag   = filemd5("${path.module}/scripts/wp_admin_subdomain.conf")
}

resource "aws_s3_bucket_object" "admin_ips_conf" {
    bucket = var.deployment_s3_bucket
    key    = "${var.service}/${var.nginx_conf_s3_key}/admin_ips.conf"
    source = templatefile("${path.module}/scripts/admin_ips.conf", {
        admin_list = var.admin_list
    })
    etag   = filemd5("${path.module}/scripts/admin_ips.conf")
}

resource "aws_s3_bucket_object" "nginx_logrotate" {
    bucket = var.deployment_s3_bucket
    key    = "${var.service}/${var.nginx_conf_s3_key}/nginx"
    source = "${path.module}/scripts/nginx"
    etag   = filemd5("${path.module}/scripts/nginx")
}
