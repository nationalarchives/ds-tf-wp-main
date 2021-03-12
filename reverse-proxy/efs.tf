# -----------------------------------------------------------------------------
# EFS storage
# -----------------------------------------------------------------------------
resource "aws_efs_file_system" "rp_efs" {
    creation_token = "${var.service}-efs-reverse-proxy-${var.environment}"
    encrypted      = true

    tags = {
        Name            = "${var.service}-efs-reverse-proxy-${var.environment}"
        Service         = var.service
        Environment     = var.environment
        CostCentre      = var.cost_centre
        Owner           = var.owner
        CreatedBy       = var.created_by
        Terraform       = true
    }
}

resource "aws_efs_mount_target" "rp_efs_private_a" {
    file_system_id = aws_efs_file_system.rp_efs.id
    subnet_id      = var.private_subnet_a_id

    security_groups = [
        var.website_efs_sg_id]
}

resource "aws_efs_mount_target" "rp_efs_private_b" {
    file_system_id = aws_efs_file_system.rp_efs.id
    subnet_id      = var.private_subnet_b_id

    security_groups = [
        var.website_efs_sg_id]
}
