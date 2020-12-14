# Public Load Balancer
resource "aws_lb" "main_public" {
    name        = "${var.service}-reverse-proxy-${var.environment}-lb"
    internal           = false
    load_balancer_type = "application"

    security_groups = [
        var.main_public_access_sg_id]

    subnets = [
        var.public_subnet_a_id,
        var.public_subnet_b_id
    ]

    tags = {
        Service         = var.service
        Environment     = var.environment
        CostCentre      = var.cost_centre
        Owner           = var.owner
        CreatedBy       = var.created_by
        Terraform       = true
    }
}

resource "aws_lb_target_group" "main_public" {
    name     = "${var.service}-reverse-proxy-${var.environment}-lb-target"
    port     = 80
    protocol = "HTTP"
    vpc_id   = var.vpc_id

    health_check {
        interval            = 30
        path                = "/healthcheck.html"
        port                = "traffic-port"
        timeout             = 5
        healthy_threshold   = 2
        unhealthy_threshold = 2
        matcher             = "200"
    }

    tags = {
        Service         = var.service
        Environment     = var.environment
        CostCentre      = var.cost_centre
        Owner           = var.owner
        CreatedBy       = var.created_by
        Terraform       = true
    }
}

resource "aws_lb_listener" "public_http_lb_listener" {
    default_action {
        target_group_arn = aws_lb_target_group.main_public.arn
        type             = "forward"
    }
    protocol          = "HTTP"
    load_balancer_arn = aws_lb.main_public.arn
    port              = 80
}

resource "aws_lb_listener" "public_https_lb_listener" {
    default_action {
        target_group_arn = aws_lb_target_group.main_public.arn
        type             = "forward"
    }
    protocol          = "HTTPS"
    load_balancer_arn = aws_lb.main_public.arn
    port              = 443
    certificate_arn   = var.public_ssl_cert_arn
    ssl_policy        = "ELBSecurityPolicy-FS-1-2-Res-2019-08"
}
