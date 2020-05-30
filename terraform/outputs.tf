output "cidr_block" {
  value = aws_vpc.this.cidr_block
}

output "aws_acm_certificate" {
    value = data.aws_acm_certificate.this.arn
}