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

resource "aws_backup_selection" "efs_backup" {
    name         = "${var.service}-reverse-proxy-${var.environment}-efs-backup"
    plan_id      = aws_backup_plan.efs_backup.id
    iam_role_arn = aws_iam_role.efs_backup.arn

    resources = [
        aws_efs_file_system.rp_efs.arn
    ]
}

resource "aws_backup_plan" "efs_backup" {
    name = "${var.service}-reverse-proxy-${var.environment}-efs-backup-plan"

    rule {
        rule_name         = "${var.service}-efs-backup-rule"
        target_vault_name = aws_backup_vault.efs_backup.name
        schedule          = var.efs_backup_schedule
        start_window      = var.efs_backup_start_window
        completion_window = var.efs_backup_completion_window
        lifecycle {
            cold_storage_after = var.efs_backup_cold_storage_after
            delete_after       = var.efs_backup_delete_after
        }
    }

    tags = {
        Service     = var.service
        Environment = var.environment
        CostCentre  = var.cost_centre
        Owner       = var.owner
        CreatedBy   = var.created_by
        Terraform   = true
    }
}

resource "aws_backup_vault" "efs_backup" {
    name        = "${var.service}-reverse-proxy-${var.environment}-efs-backup-vault"
    kms_key_arn = var.efs_backup_kms_key_arn

    tags = {
        Service     = var.service
        Environment = var.environment
        CostCentre  = var.cost_centre
        Owner       = var.owner
        CreatedBy   = var.created_by
        Terraform   = true
    }
}
