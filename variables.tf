# Variables modulo ASG
variable "asg_vpc" {}
variable "vpc_cidr" {}

variable "asg_subnets" {
  type = list(string)
}

variable "sg_ingress_ports" {
  type = map(string)
}

variable "lt_config" {
  type = map(string)
}

variable "asg_config" {
  type = map(string)
}

variable "asg_tg_arn" {}
