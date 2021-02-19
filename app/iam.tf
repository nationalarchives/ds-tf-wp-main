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

resource "aws_iam_role_policy_attachment" "smm_ec2_role_policy" {
    policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
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
  name               = "${var.service}-wp-${var.environment}-efs-backup"
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

resource "aws_iam_role_policy_attachment" "example" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
  role       = aws_iam_role.efs_backup.name
}
