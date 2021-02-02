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

variable "website_efs_sg_id" {}

variable "website_public_access_sg_id" {}

variable "public_ssl_cert_arn" {}

variable "ami_id" {}

variable "instance_type" {}

variable "key_name" {}

variable "efs_mount_dir" {}

variable "deployment_s3_bucket" {}

variable "nginx_conf_s3_key" {}

variable "int_domain_name" {}

variable "public_domain_name" {}

variable "website_public_lb_dns_name" {}

variable "website_public_lb_zone_id" {}

variable "everyone" {}
