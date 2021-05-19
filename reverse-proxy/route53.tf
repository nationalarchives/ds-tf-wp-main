# -----------------------------------------------------------------------------
# Internal domain name
# -----------------------------------------------------------------------------
resource "aws_route53_zone" "internal" {
    name = var.int_domain_name

    tags = {
        Service         = var.service
        Environment     = var.environment
        CostCentre      = var.cost_centre
        Owner           = var.owner
        CreatedBy       = var.created_by
        Terraform       = true
    }
}

resource "aws_route53_record" "domain_name" {
    zone_id = aws_route53_zone.internal.zone_id
    name    = var.int_domain_name
    type    = "A"

    alias {
        name                   = aws_lb.rp_public.dns_name
        zone_id                = aws_lb.rp_public.zone_id
        evaluate_target_health = true
    }
}

resource "aws_route53_record" "sub_domain_names" {
    zone_id = aws_route53_zone.internal.zone_id
    name    = "*.${var.int_domain_name}"
    type    = "A"

    alias {
        name                   = aws_lb.rp_public.dns_name
        zone_id                = aws_lb.rp_public.zone_id
        evaluate_target_health = true
    }
}

resource "aws_route53_record" "acme_challenge_record" {
    zone_id = aws_route53_zone.internal.zone_id
    name    = "_acme-challenge.${var.int_domain_name}"
    type    = "TXT"
    ttl     = "300"
    records = [
        "inital-text"]
}

# -----------------------------------------------------------------------------
# Public domain name (reverse proxy) and alias to reverse proxy instance
# -----------------------------------------------------------------------------
resource "aws_route53_zone" "reverse_proxy_public" {
    name = var.public_domain_name

    tags = {
        Service         = var.service
        Environment     = var.environment
        CostCentre      = var.cost_centre
        Owner           = var.owner
        CreatedBy       = var.created_by
        Terraform       = true
    }
}

resource "aws_route53_record" "reverse_proxy_public" {
    zone_id = aws_route53_zone.reverse_proxy_public.zone_id
    name    = var.public_domain_name
    type    = "A"

    alias {
        name                   = aws_lb.rp_public.dns_name
        zone_id                = aws_lb.rp_public.zone_id
        evaluate_target_health = true
    }
}
