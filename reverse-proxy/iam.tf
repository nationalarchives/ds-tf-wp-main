# -----------------------------------------------------------------------------
# Reverse proxy role, policy and instance profile
# -----------------------------------------------------------------------------
resource "aws_iam_role" "rp_assume_role" {
    name               = "${var.service}-reverse-proxy-${var.environment}-role"
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
            "Sid": ""
        }
    ]
}
EOF
}

resource "aws_iam_policy" "rp_config_s3" {
    name        = "${var.service}-reverse-proxy-${var.environment}-s3-policy"
    description = "Access to nginx configuration files"

    policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket"
      ],
     "Resource": [
        "arn:aws:s3:::${var.deployment_s3_bucket}"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject"
      ],
      "Resource": [
         "arn:aws:s3:::${var.deployment_s3_bucket}/${var.service}/*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "rp_s3_role_policy" {
    policy_arn = aws_iam_policy.rp_config_s3.arn
    role       = aws_iam_role.rp_assume_role.id
}

resource "aws_iam_instance_profile" "rp" {
    name = "${var.service}-reverse-proxy-${var.environment}-profile"
    path = "/"
    role = aws_iam_role.rp_assume_role.name
}
