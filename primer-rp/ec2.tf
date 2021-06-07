resource "aws_instance" "rp_primer" {
    ami                         = var.ami_id
    associate_public_ip_address = var.public_ip
    instance_type               = var.instance_type
    key_name                    = var.key_name
    subnet_id                   = var.subnet_id
    iam_instance_profile        = aws_iam_instance_profile.primer_rp_profile.name
    vpc_security_group_ids      = [
        var.sg_id
    ]

    root_block_device {
        volume_size = var.volume_size
        encrypted   = true
    }

    user_data = var.user_data

    tags = merge(var.tags, {
        Name = var.instance_name
    })
}
