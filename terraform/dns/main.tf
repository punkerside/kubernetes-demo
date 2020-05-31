variable "profile" {}
variable "region" {}
variable "domain" {}
variable "lb_name" {}
variable "services" {
  type = list(string)
}


provider "aws" {
    version = "~> 2.1"
    profile = var.profile
    region  = var.region
}

data "aws_route53_zone" "this" {
  name         = "${var.domain}."
  private_zone = false
}

data "aws_elb" "this" {
  name = var.lb_name
}

resource "aws_route53_record" "this" {
  count   = length(var.services)
  zone_id = data.aws_route53_zone.this.id
  name    = "${element(var.services, count.index)}.${var.domain}"
  type    = "A"

  alias {
    name                   = data.aws_elb.this.dns_name
    zone_id                = data.aws_elb.this.zone_id
    evaluate_target_health = false
  }
}