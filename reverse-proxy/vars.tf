variable "environment" {}

variable "service" {}

variable "cost_centre" {}

variable "owner" {}

variable "created_by" {}

variable "vpc_id" {}

variable "public_subnet_a_id" {}

variable "public_subnet_b_id" {}

variable "private_subnet_a_id" {}

variable "private_subnet_b_id" {}

variable "asg_max_size" {}

variable "asg_min_size" {}

variable "asg_desired_capacity" {}

variable "asg_health_check_grace_period" {}

variable "asg_health_check_type" {}

variable "patch_group_name" {}

variable "public_ssl_cert_arn" {}

variable "sub_sub_domain_ssl_cert_arn" {}

variable "ami_id" {}

variable "instance_type" {}

variable "key_name" {}

variable "efs_mount_dir" {}

variable "deployment_s3_bucket" {}
variable "logfile_s3_bucket" {}

variable "nginx_conf_s3_key" {}

variable "editorial_domain_name" {}

variable "public_domain_name" {}

variable "everyone" {}

variable "efs_backup_schedule" {}

variable "efs_backup_start_window" {}

variable "efs_backup_completion_window" {}

variable "efs_backup_cold_storage_after" {}

variable "efs_backup_delete_after" {}

variable "efs_backup_kms_key_arn" {}
