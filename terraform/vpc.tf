resource "aws_vpc" "this" {
  cidr_block           = var.cidr_vpc
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name    = "${var.project}-${var.env}"
    Project = "${var.project}"
    Env     = "${var.env}"
    "kubernetes.io/cluster/${var.project}-${var.env}" = "shared"
  }
}