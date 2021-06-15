variable "instance_role" {}
variable "instance_profile" {}
variable "instance_role_policy_name" {}

variable "ami_id" {}
variable "ami_name" {}

variable "instance_name" {}
variable "key_name" {}
variable "vpc_id" {}
variable "subnet_id" {}
variable "volume_size" {}
variable "debug_cidr" {}
variable "tags" {}
variable "instance_type" {
    default = "t3a.medium"
}
variable "public_ip" {
    default = false
}

variable "s3_logfile_bucket" {}
variable "s3_logfile_root" {}
variable "s3_deployment_bucket" {}
variable "s3_deployment_root" {}
