resource "aws_s3_bucket_object" "nginx_conf" {
    bucket  = var.deployment_s3_bucket
    key     = "${var.service}/${var.nginx_conf_s3_key}"
    source  = "scripts/nginx.conf"
    etag    = filemd5("scripts/nginx.conf")
}
