# -----------------------------------------------------------------------------
# IAM instance role and instance profile
# -----------------------------------------------------------------------------
resource "aws_iam_role" "website" {
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

resource "aws_iam_policy" "wp_deployment_s3" {
    name        = "${var.service}-wp-${var.environment}-s3-policy"
    description = "WP deployment S3 access"

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
        "s3:GetObject",
        "s3:PutObject",
        "s3:PutObjectAcl"
      ],
      "Resource": [
         "arn:aws:s3:::${var.deployment_s3_bucket}/${var.service}/*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "wp_deployment_s3_policy" {
    policy_arn = aws_iam_policy.wp_deployment_s3.arn
    role       = aws_iam_role.website.id
}

resource "aws_iam_role_policy_attachment" "smm_ec2_role_policy" {
    policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
    role       = aws_iam_role.website.id
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent_role_policy" {
    policy_arn = "arn:aws:iam::aws:policy/service-role/CloudWatchAgentServerPolicy"
    role       = aws_iam_role.website.id
}

resource "aws_iam_instance_profile" "website" {
    name = "${var.service}-wp-${var.environment}-iam-instance-profile"
    path = "/"
    role = aws_iam_role.website.name
}

# -----------------------------------------------------------------------------
# IAM EFS backup role
# -----------------------------------------------------------------------------
resource "aws_iam_role" "efs_backup" {
  name               = "${var.service}-wp-${var.environment}-efs-backup-role"
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": ["sts:AssumeRole"],
      "Effect": "allow",
      "Principal": {
        "Service": ["backup.amazonaws.com"]
      }
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "efs_backup" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
  role       = aws_iam_role.efs_backup.name
}
