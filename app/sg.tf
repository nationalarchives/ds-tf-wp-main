# -----------------------------------------------------------------------------
# Security Group application access (Load balancer and WordPress ec2)
# -----------------------------------------------------------------------------
resource "aws_security_group" "website_app" {
    name        = "${var.service}-wp-${var.environment}-app-sg"
    description = "WordPress Security access to applicatoin"
    vpc_id      = var.vpc_id

    tags = {
        Name        = "${var.service}-wp-${var.environment}-app-sg"
        Service     = var.service
        Environment = var.environment
        CostCentre  = var.cost_centre
        Owner       = var.owner
        CreatedBy   = var.created_by
        Terraform   = true
    }
}

resource "aws_security_group_rule" "app_http_ingress" {
    from_port                = 80
    protocol                 = "tcp"
    security_group_id        = aws_security_group.website_app.id
    to_port                  = 80
    type                     = "ingress"
    source_security_group_id = var.reverse_proxy_app_sg_id
}

resource "aws_security_group_rule" "http_ingress" {
    from_port                = 80
    protocol                 = "tcp"
    security_group_id        = aws_security_group.website_app.id
    to_port                  = 80
    type                     = "ingress"
    source_security_group_id = aws_security_group.website_app.id
}

resource "aws_security_group_rule" "app_http_egress" {
    security_group_id = aws_security_group.website_app.id
    type              = "egress"
    from_port         = 0
    to_port           = 0
    protocol          = "-1"
    cidr_blocks       = [
        var.everyone]
}

resource "aws_security_group_rule" "app_https_ingress" {
    from_port                = 443
    protocol                 = "tcp"
    security_group_id        = aws_security_group.website_app.id
    to_port                  = 443
    type                     = "ingress"
    source_security_group_id = var.reverse_proxy_app_sg_id
}

resource "aws_security_group_rule" "https_ingress" {
    from_port                = 443
    protocol                 = "tcp"
    security_group_id        = aws_security_group.website_app.id
    to_port                  = 443
    type                     = "ingress"
    source_security_group_id = aws_security_group.website_app.id
}

# -----------------------------------------------------------------------------
# Security Group EFS access
# -----------------------------------------------------------------------------
resource "aws_security_group" "website_efs" {
    name        = "${var.service}-wp-${var.environment}-efs-access"
    description = "WordPress Security access to EFS storage"
    vpc_id      = var.vpc_id

    tags = {
        Name        = "${var.service}-wp-${var.environment}-efs-access"
        Environment = var.environment
        Terraform   = "True"
        Service     = var.service
    }
}

resource "aws_security_group_rule" "efs_ingress" {
    from_port                = 0
    protocol                 = "tcp"
    security_group_id        = aws_security_group.website_efs.id
    to_port                  = 65535
    type                     = "ingress"
    source_security_group_id = aws_security_group.website_app.id
}

resource "aws_security_group_rule" "efs_egress" {
    security_group_id = aws_security_group.website_efs.id
    type              = "egress"
    from_port         = 0
    to_port           = 0
    protocol          = "-1"
    cidr_blocks       = [
        var.everyone]
}
