resource "aws_efs_file_system" "rp_efs" {
    creation_token = "${var.service}-reverse-proxy-${var.environment}-efs"
    encrypted      = true

    tags = {
        Name        = "${var.service}-reverse-proxy-${var.environment}-efs"
        Service     = var.service
        Environment = var.environment
        Terraform   = true
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
