resource "aws_nat_gateway" "this" {
  count         = length(var.cidr_pri)
  allocation_id = element(aws_eip.this.*.id, count.index)
  subnet_id     = element(aws_subnet.pub.*.id, count.index)

  tags = {
    Name    = "${var.project}-${var.env}"
    Project = var.project
    Env     = var.env
  }
}