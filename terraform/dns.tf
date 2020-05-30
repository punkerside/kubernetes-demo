# resource "aws_route53_record" "this" {
#   count   = length(var.services)

#   zone_id = data.aws_route53_zone.this.id
#   name    = "${element(var.services, count.index)}.${var.domain}"
#   type    = "A"

#   alias {
#     name                   = var.dns_name
#     zone_id                = var.zone_id
#     evaluate_target_health = false
#   }
# }