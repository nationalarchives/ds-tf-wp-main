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
