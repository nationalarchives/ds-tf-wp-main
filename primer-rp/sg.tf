# -----------------------------------------------------------------------------
# Security group reverse proxy primer instance
# - allowing ports 22 from VPN
# -----------------------------------------------------------------------------
resource "aws_security_group" "rp" {
    name        = "primer-reverse-proxy-sg"
    description = "Primer peverse proxy security group - delete with primer instance"
    vpc_id      = var.vpc_id

    tags = merge(var.tags, {
        Name = "primer-reverse-proxy-sg"
    })
}

resource "aws_security_group_rule" "rp_ssh_ingress" {
    from_port         = 22
    to_port           = 22
    protocol          = "tcp"
    security_group_id = aws_security_group.rp.id
    type              = "ingress"
    cidr_blocks       = [
        var.debug_cidr]
}

resource "aws_security_group_rule" "rp_egress" {
    from_port         = 0
    to_port           = 0
    protocol          = "-1"
    security_group_id = aws_security_group.rp.id
    type              = "egress"
    cidr_blocks       = [
        "0.0.0.0/0"]
}
