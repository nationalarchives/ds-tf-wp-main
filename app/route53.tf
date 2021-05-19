# -----------------------------------------------------------------------------
# Private zone CNAME record for WordPress load balancer
# -----------------------------------------------------------------------------
resource "aws_route53_record" "app" {
    zone_id = var.route53_local_zone_id
    name    = "website.${var.environment}.local"
    type = "CNAME"
    ttl = 15

    records = [
        aws_lb.website_internal.dns_name
    ]
}
