locals {
    ts = formatdate("YYYY-MM-DD hh-mm-ss", timestamp())
}

resource "aws_ami_from_instance" "rp_ami" {
    name               = "${local.environment}-${local.service} ${local.ts}"
    source_instance_id = aws_instance.wp_primer

    tags = merge(var.tags, {
        Name = var.ami_name
    })
}

# clean up
# 1. remove the ami from state
# 2. destroy instance
resource "null_resource" "remove_ec2" {
    depends_on = [aws_ami_from_instance.rp_ami]

    provisioner "run_terraform" {
        inline = [
            "terraform state rm aws_ami_from_instance.rp_ami",
            "terraform destroy aws_instance.rp_primer"
        ]
    }
}
