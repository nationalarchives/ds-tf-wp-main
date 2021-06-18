# -----------------------------------------------------------------------------
# Launch config
# -----------------------------------------------------------------------------
resource "aws_launch_configuration" "rp" {
    name_prefix          = "${var.service}rp"
    image_id             = var.ami_id
    instance_type        = var.instance_type
    iam_instance_profile = aws_iam_instance_profile.rp.name
    user_data            = templatefile("${path.module}/scripts/userdata.sh", {
        service              = var.service,
        mount_target         = aws_efs_file_system.rp_efs.dns_name,
        mount_dir            = var.efs_mount_dir,
        deployment_s3_bucket = var.deployment_s3_bucket,
        nginx_folder_s3_key  = var.nginx_folder_s3_key
    })
    key_name             = var.key_name

    security_groups = [
        aws_security_group.rp.id]

    root_block_device {
        volume_size = 100
        encrypted   = true
    }

    lifecycle {
        create_before_destroy = true
    }
}
