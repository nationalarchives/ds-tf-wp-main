#
#
# WordPress Security Group public access (load balancer)
resource "aws_security_group" "main_public" {
    name        = "${var.service}-wp-${var.environment}-public-sg"
    description = "WordPress Security Group HTTP and HTTPS access"
    vpc_id      = var.vpc_id

    tags = {
        Name        = "${var.service}-wp-${var.environment}-public-sg"
        Service     = var.service
        Environment = var.environment
        CostCentre  = var.cost_centre
        Owner       = var.owner
        CreatedBy   = var.created_by
        Terraform   = true
    }
}

resource "aws_security_group_rule" "main_public_http_ingress" {
    from_port         = 80
    protocol          = "tcp"
    security_group_id = aws_security_group.main_public.id
    to_port           = 80
    type              = "ingress"
    cidr_blocks       = [
        var.everyone]
}

resource "aws_security_group_rule" "main_public_http_egress" {
    security_group_id = aws_security_group.main_public.id
    type              = "egress"
    from_port         = 0
    to_port           = 0
    protocol          = "-1"
    cidr_blocks       = [
        var.everyone]
}

resource "aws_security_group_rule" "main_public_https_ingress" {
    from_port         = 443
    protocol          = "tcp"
    security_group_id = aws_security_group.main_public.id
    to_port           = 443
    type              = "ingress"
    cidr_blocks       = [
        var.everyone]
}

#
#
# WordPress Security Group applicatoin access
resource "aws_security_group" "main_app" {
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

resource "aws_security_group_rule" "main_app_http_ingress" {
    from_port                = 80
    protocol                 = "tcp"
    security_group_id        = aws_security_group.main_app.id
    to_port                  = 80
    type                     = "ingress"
    source_security_group_id = aws_security_group.main_public.id
}

resource "aws_security_group_rule" "main_app_http_egress" {
    security_group_id = aws_security_group.main_app.id
    type              = "egress"
    from_port         = 0
    to_port           = 0
    protocol          = "-1"
    cidr_blocks       = [
        var.everyone]
}

resource "aws_security_group_rule" "main_app_https_ingress" {
    from_port                = 443
    protocol                 = "tcp"
    security_group_id        = aws_security_group.main_app.id
    to_port                  = 443
    type                     = "ingress"
    source_security_group_id = aws_security_group.main_public.id
}

#
#
# WordPress Security Group EFS access
resource "aws_security_group" "main_efs" {
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

resource "aws_security_group_rule" "main_efs_ingress" {
    from_port                = 0
    protocol                 = "tcp"
    security_group_id        = aws_security_group.main_efs.id
    to_port                  = 65535
    type                     = "ingress"
    source_security_group_id = aws_security_group.main_efs.id
}

resource "aws_security_group_rule" "main_efs_egress" {
    security_group_id = aws_security_group.main_efs.id
    type              = "egress"
    from_port         = 0
    to_port           = 0
    protocol          = "-1"
    cidr_blocks       = [
        var.everyone]
}
