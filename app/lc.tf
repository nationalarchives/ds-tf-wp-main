# -----------------------------------------------------------------------------
# Launch config
# -----------------------------------------------------------------------------
resource "aws_launch_configuration" "website" {
    name_prefix          = "${var.service}wp"
    image_id             = var.ami_id
    instance_type        = var.instance_type
    iam_instance_profile = aws_iam_instance_profile.website.name
    user_data            = data.template_file.ec2_userdata.rendered
    key_name             = var.key_name

    security_groups = [
        aws_security_group.website_app.id]

    root_block_device {
        volume_size = 100
        encrypted = true
    }

    lifecycle {
        create_before_destroy = true
    }
}

data "template_file" "ec2_userdata" {
    template = file("${path.module}/scripts/userdata.sh")

    vars = {
        mount_target       = aws_efs_file_system.website.dns_name
        mount_dir          = var.efs_mount_dir
        db_host            = "db.${var.service}wp.${var.environment}.local"
        db_name            = var.wp_db_name
        db_user            = var.wp_db_username
        db_pass            = var.wp_db_password
        service            = var.service
        environment        = var.environment
        domain             = var.wp_domain_name
        wpms_smtp_password = var.wpms_smtp_password
    }
}
