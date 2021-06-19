# -----------------------------------------------------------------------------
# IAM instance role and instance profile
# -----------------------------------------------------------------------------
resource "aws_iam_role" "primer_rp" {
    name               = var.instance_role
    assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": "RPAssumeRole"
        }
    ]
}
EOF
}

resource "aws_iam_policy" "rp_deployment_s3" {
    name        = var.instance_role_policy_name
    description = "RP deployment S3 access"

    policy = templatefile("${path.module}/scripts/instance-role-policy.json", {
        s3_deployment_bucket = var.s3_deployment_bucket,
        s3_deployment_root   = var.s3_deployment_root
    })
}

resource "aws_iam_role_policy_attachment" "rp_deployment_s3_policy" {
    policy_arn = aws_iam_policy.rp_deployment_s3.arn
    role       = aws_iam_role.primer_rp.id
}

resource "aws_iam_instance_profile" "primer_rp_profile" {
    name = var.instance_profile
    path = "/"
    role = aws_iam_role.primer_rp.name
}

resource "aws_iam_role_policy_attachment" "rp_ssm_policy" {
    policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
    role       = aws_iam_role.primer_rp.id
}
