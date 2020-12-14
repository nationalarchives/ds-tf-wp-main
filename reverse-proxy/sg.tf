# -----------------------------------------------------------------------------
# Security group reverse proxy instance
# - allowing ports 22, 53 and 80
# -----------------------------------------------------------------------------
resource "aws_security_group" "rp" {
    name        = "${var.service}-reverse-proxy-${var.environment}-sg"
    description = "reverse proxy security group"
    vpc_id      = data.terraform_remote_state.vpc.outputs.vpc

    tags = {
        Name            = "${var.service}-reverse-proxy-${var.environment}-sg"
        Service         = var.service
        ApplicationType = var.app
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
    security_group_id = aws_security_group.rp_access.id
    type              = "ingress"
    source_security_group_id = var.main_app_access_sg_id
}

resource "aws_security_group_rule" "rp_ssh_ingress" {
    from_port         = 22
    to_port           = 22
    protocol          = "tcp"
    security_group_id = aws_security_group.rp_access.id
    type              = "ingress"
    source_security_group_id = var.main_public_access_sg_id
}

resource "aws_security_group_rule" "rp_dns_ingress" {
    from_port         = 53
    to_port           = 53
    protocol          = "tcp"
    security_group_id = aws_security_group.rp_access.id
    type              = "ingress"
    cidr_blocks       = ""
}

resource "aws_security_group_rule" "rp_egress" {
    from_port         = 0
    to_port           = 0
    protocol          = "-1"
    security_group_id = aws_security_group.rp_access.id
    type              = "egress"
    cidr_blocks       = var.everyone
}