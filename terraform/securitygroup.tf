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