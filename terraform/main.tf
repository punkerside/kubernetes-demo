provider "aws" {
    version = "~> 2.1"
}

data "aws_route53_zone" "this" {
  name         = "${var.domain}."
  private_zone = false
}

resource "aws_route53_record" "this" {
  count   = length(var.services)

  zone_id = data.aws_route53_zone.this.id
  name    = "${element(var.services, count.index)}.${var.domain}"
  type    = "A"

  alias {
    name                   = var.dns_name
    zone_id                = var.zone_id
    evaluate_target_health = false
  }
}

variable "dns_name" {}
variable "zone_id" {}
variable "domain" {}
variable "services" {
  type = list(string)
  default = ["prometheus","grafana","kibana","guestbook"]
}