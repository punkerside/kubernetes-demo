resource "aws_eip" "this" {
  count            = length(var.cidr_pub)
  vpc              = true

  tags = {
    Name    = "${var.project}-${var.env}"
    Project = var.project
    Env     = var.env
  }
}