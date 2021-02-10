resource "aws_instance" "wp_primer" {
    ami                         = var.ami_id
    associate_public_ip_address = var.public_ip
    instance_type               = var.instance_type
    key_name                    = var.key_name
    subnet_id                   = var.subnet_id
    vpc_security_group_ids      = [
        var.website_app_sg_id
    ]

    root_block_device {
        volume_size = var.volume_size
        encrypted   = true
    }
    
    user_data            = data.template_file.ec2_user_data.rendered

    tags = {
        Name            = "${var.service}-wp-primer-${var.environment}"
        Service         = var.service
        Environment     = var.environment
        CostCentre      = var.cost_centre
        Owner           = var.owner
        CreatedBy       = var.created_by
        Terraform       = true
    }
}

data "template_file" "ec2_user_data" {
    template = file("${path.module}/scripts/userdata.sh")

    vars = {
        environment  = var.environment
        github_token = var.github_token
        db_host            = "db.${var.service}wp.${var.environment}.local"
        db_name            = var.wp_db_name
        db_user            = var.wp_db_username
        db_pass            = var.wp_db_password
        environment        = var.environment
        domain             = var.wp_domain_name
    }
}