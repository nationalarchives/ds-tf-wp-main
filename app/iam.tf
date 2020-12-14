resource "aws_iam_role" "main" {
    name               = "${var.service}-wp-${var.environment}-assume-role"
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
            "Sid": "WPAssumeRole"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "smm_ec2_role_policy" {
    policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
    role       = aws_iam_role.main.id
}

resource "aws_iam_instance_profile" "main" {
    name = "${var.service}-wp-${var.environment}-iam-instance-profile"
    path = "/"
    role = aws_iam_role.main.name
}
