variable "region" {}
variable "domain" {}
variable "project" {}
variable "env" {}
variable "eks_version" {}
variable "cidr_vpc" {}
variable "desired_capacity" {}
variable "max_size" {}
variable "min_size" {}
variable "on_demand_percentage_above_base_capacity" {}
variable "cidr_pri" {
    type = list(string)
}
variable "cidr_pub" {
    type = list(string)
}
variable "instance_types" {
    type = list(string)
}
