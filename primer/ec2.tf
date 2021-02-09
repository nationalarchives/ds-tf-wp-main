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
        Name            = "website-wp-primer-${var.environment}"
        Service         = var.service
        Environment     = var.environment
        CostCentre      = var.cost_centre
        Owner           = var.owner
        CreatedBy       = var.created_by
        Terraform       = true
    }
}

data "template_file" "ec2_user_data" {
    template = file("${path.module}/script/userdata.sh")

    vars = {
        environment  = var.environment
        github_token = var.github_token
    }
}