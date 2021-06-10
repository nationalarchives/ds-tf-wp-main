resource "aws_ami_from_instance" "rp_ami" {
    name               = var.ami_name
    source_instance_id = var.source_instance_id

    tags = merge(var.tags, {
        Name = var.ami_name
    })
}
