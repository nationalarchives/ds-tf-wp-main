variable "environment" {}

variable "service" {}

variable "cost_centre" {}

variable "owner" {}

variable "created_by" {}

variable "vpc_id" {}

variable "ami_id" {}

variable "website_app_sg_id" {}

variable "instance_type" {
    default = "t2.micro"
}

variable "public_ip" {
    default = false
}

variable "key_name" {}

variable "subnet_id" {}

variable "volume_size" {}

variable "github_token" {}

variable "wp_db_name" {}

variable "wp_db_username" {}

variable "wp_db_password" {}

variable "wp_int_siteurl" {}

variable "wp_public_siteurl" {}

variable "wp_editor_siteurl" {}

variable "deployment_s3_bucket" {}

variable "ses_username" {}

variable "ses_password" {}

variable "ses_host" {}

variable "ses_port" {}

variable "ses_secure" {}

variable "ses_from_email" {}

variable "ses_from_name" {}
