variable "deployment_s3_bucket" {}
variable "nginx_conf_s3_key" {}

variable "service" {}

# variables for scripts
variable "environment" {}
variable "set_real_ip_from" {}
variable "resolver" {}
variable "ups_website" {}
variable "ups_appslb" {}
variable "ups_legacy_apps" {}
variable "admin_list" {}
