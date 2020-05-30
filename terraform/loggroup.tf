resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/eks/${var.project}-${var.env}/cluster"
  retention_in_days = 30
}