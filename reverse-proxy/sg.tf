# -----------------------------------------------------------------------------
# Security Group public access (load balancer)
# -----------------------------------------------------------------------------
resource "aws_security_group" "website_lb_app" {
    name        = "${var.service}-wp-${var.environment}-lb-app-sg"
    description = "WordPress Security Group HTTP and HTTPS access"
    vpc_id      = var.vpc_id

    tags = {
        Name        = "${var.service}-wp-${var.environment}-lb-app-sg"
        Service     = var.service
        Environment = var.environment
        CostCentre  = var.cost_centre
        Owner       = var.owner
        CreatedBy   = var.created_by
        Terraform   = true
    }
}

resource "aws_security_group_rule" "lb_app_http_ingress" {
    from_port         = 80
    protocol          = "tcp"
    security_group_id = aws_security_group.website_app.id
    to_port           = 80
    type              = "ingress"
    cidr_blocks       = [
        var.everyone]
}

resource "aws_security_group_rule" "lb_app_http_egress" {
    security_group_id = aws_security_group.website_app.id
    type              = "egress"
    from_port         = 0
    to_port           = 0
    protocol          = "-1"
    cidr_blocks       = [
        var.everyone]
}

resource "aws_security_group_rule" "lb_app_https_ingress" {
    from_port         = 443
    protocol          = "tcp"
    security_group_id = aws_security_group.website_app.id
    to_port           = 443
    type              = "ingress"
    cidr_blocks       = [
        var.everyone]
}

# -----------------------------------------------------------------------------
# Security group reverse proxy instance
# - allowing ports 22, 53 and 80
# -----------------------------------------------------------------------------
resource "aws_security_group" "rp" {
    name        = "${var.service}-reverse-proxy-${var.environment}-sg"
    description = "Reverse proxy security group"
    vpc_id      = var.vpc_id

    tags = {
        Name            = "${var.service}-reverse-proxy-${var.environment}-sg"
        Service         = var.service
        Environment     = var.environment
        CostCentre      = var.cost_centre
        Owner           = var.owner
        CreatedBy       = var.created_by
        Terraform       = true
    }
}

resource "aws_security_group_rule" "rp_http_ingress" {
    from_port         = 80
    to_port           = 80
    protocol          = "tcp"
    security_group_id = aws_security_group.rp.id
    type              = "ingress"
    source_security_group_id = var.website_public_access_sg_id
}

resource "aws_security_group_rule" "rp_ssh_ingress" {
    from_port         = 22
    to_port           = 22
    protocol          = "tcp"
    security_group_id = aws_security_group.rp.id
    type              = "ingress"
    source_security_group_id = var.website_public_access_sg_id
}

resource "aws_security_group_rule" "rp_egress" {
    from_port         = 0
    to_port           = 0
    protocol          = "-1"
    security_group_id = aws_security_group.rp.id
    type              = "egress"
    cidr_blocks       = [var.everyone]
}

# -----------------------------------------------------------------------------
# Security group reverse proxy EFS
# -----------------------------------------------------------------------------
resource "aws_security_group" "rp_efs" {
    name        = "${var.service}-efs-reverse-proxy-${var.environment}-sg"
    description = "Reverse proxy EFS storage security group"
    vpc_id      = var.vpc_id

    tags = {
        Name            = "${var.service}-efs-reverse-proxy-${var.environment}-sg"
        Service         = var.service
        Environment     = var.environment
        CostCentre      = var.cost_centre
        Owner           = var.owner
        CreatedBy       = var.created_by
        Terraform       = true
    }
}

resource "aws_security_group_rule" "rp_efs_ingress" {
    from_port                = 0
    protocol                 = "tcp"
    security_group_id        = aws_security_group.rp_efs.id
    to_port                  = 65535
    type                     = "ingress"
    source_security_group_id = aws_security_group.rp.id
}

resource "aws_security_group_rule" "rp_efs_egress" {
    security_group_id = aws_security_group.rp_efs.id
    type              = "egress"
    from_port         = 0
    to_port           = 0
    protocol          = "-1"
    cidr_blocks       = [var.everyone]
}
