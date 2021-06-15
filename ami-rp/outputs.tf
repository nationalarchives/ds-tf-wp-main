output "ami_id" {
    value = aws_ami_from_instance.rp_ami.id
}

output "ami_arn" {
    value = aws_ami_from_instance.rp_ami.arn
}

output "ami_name" {
    value = aws_ami_from_instance.rp_ami.name
}
