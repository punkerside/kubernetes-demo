resource "aws_subnet" "pri" {
    count                   = length(var.cidr_pri)
    vpc_id                  = aws_vpc.this.id
    cidr_block              = element(var.cidr_pri, count.index)
    availability_zone       = element(local.aws_availability_zones, count.index)
    map_public_ip_on_launch = false

    tags = {
        Name    = "${var.project}-${var.env}-pri"
        Project = var.project
        Env     = var.env
        "kubernetes.io/cluster/${var.project}-${var.env}" = "shared"
    }
}

resource "aws_subnet" "pub" {
    count                   = length(var.cidr_pub)
    vpc_id                  = aws_vpc.this.id
    cidr_block              = element(var.cidr_pub, count.index)
    availability_zone       = element(local.aws_availability_zones, count.index)
    map_public_ip_on_launch = true

    tags = {
        Name    = "${var.project}-${var.env}-pub"
        Project = var.project
        Env     = var.env
        "kubernetes.io/cluster/${var.project}-${var.env}" = "shared"
    }
}