resource "aws_ami_from_instance" "rp_ami" {
    name               = var.ami_name
    source_instance_id = aws_instance.rp_primer.id

    tags = merge(var.tags, {
        Name = var.ami_name
    })
}

# clean up
# 1. remove the ami from state
# 2. destroy instance
resource "null_resource" "run_terraform" {
    depends_on = [aws_ami_from_instance.rp_ami]

    provisioner "local-exec" {
        inline = [
            "terraform state rm aws_ami_from_instance.rp_ami",
            "terraform destroy aws_instance.rp_primer"
        ]
    }
}
