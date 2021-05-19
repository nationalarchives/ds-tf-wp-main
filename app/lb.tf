# -----------------------------------------------------------------------------
# Internal Load Balancer
# -----------------------------------------------------------------------------
resource "aws_lb" "website_internal" {
    name        = "${var.service}-wp-${var.environment}-lb-internal"
    internal           = true
    load_balancer_type = "application"

    security_groups = [
        aws_security_group.website_app.id]

    subnets = [
        var.private_subnet_a_id,
        var.private_subnet_b_id
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

resource "aws_lb_target_group" "website_internal" {
    name     = "${var.service}-wp-${var.environment}-internal"
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

resource "aws_lb_listener" "internal_http" {
    default_action {
        type             = "forward"
        target_group_arn = aws_lb_target_group.website_internal.arn
    }
    protocol          = "HTTP"
    load_balancer_arn = aws_lb.website_internal.arn
    port              = 80
}
