variable "env" {}
variable "components" {}
variable "tags" {}
variable "vpc_id" {}
variable "sg-ssh-ingress-cidr" {}
variable "sg-ingress-cidr" {}

variable "image_id" {}
variable "instance_type" {}


variable "desired_capacity" {}
variable "max_size" {}
variable "min_size" {}

variable "subnet_ids" {}
variable "dns_name" {}
variable "listner" {}
variable "priority" {}
variable "port" {}