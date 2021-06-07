variable "instance_role" {}
variable "instance_profile" {}
variable "instance_role_policy_name" {}
variable "instance_role_policy" {}

variable "ami_id" {}
variable "ami_name" {}

variable "instance_name" {}
variable "key_name" {}
variable "subnet_id" {}
variable "volume_size" {}
variable "tags" {}
variable "sg_id" {}
variable "user_data" {}
variable "instance_type" {
    default = "t3a.medium"
}
variable "public_ip" {
    default = false
}
