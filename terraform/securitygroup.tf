resource "aws_security_group" "cluster" {
  name_prefix = "${var.project}-${var.env}-cluster"
  description = "virtual firewall that controls the traffic"
  vpc_id      = aws_vpc.this.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project}-${var.env}-cluster"
    Project = var.project
    Env     = var.env
  }

  lifecycle  {
    create_before_destroy = true
  }
}

resource "aws_security_group" "node" {
  name_prefix = "${var.project}-${var.env}-node"
  description = "virtual firewall that controls the traffic"
  vpc_id      = aws_vpc.this.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.cluster.id]
  }

  tags = {
    Name    = "${var.project}-${var.env}-node"
    Project = var.project
    Env     = var.env
    "kubernetes.io/cluster/${var.project}-${var.env}" = "owned"
  }

  lifecycle  {
    create_before_destroy = true
    ignore_changes        = [ingress]
  }
}

resource "aws_security_group_rule" "node" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.node.id
  security_group_id        = aws_security_group.node.id
}