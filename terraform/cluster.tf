resource "aws_eks_cluster" "this" {
  name     = "${var.project}-${var.env}"
  role_arn = aws_iam_role.cluster.arn
  version  = var.eks_version

  vpc_config {
    subnet_ids              = concat(tolist(aws_subnet.pri.*.id), tolist(aws_subnet.pub.*.id))
    security_group_ids      = [aws_security_group.cluster.id]
    endpoint_private_access = false
    endpoint_public_access  = true
  }

  enabled_cluster_log_types = ["api"]

  depends_on = [aws_iam_role_policy_attachment.AmazonEKSClusterPolicy,
                aws_iam_role_policy_attachment.AmazonEKSServicePolicy,
                aws_cloudwatch_log_group.this]

  tags = {
    Name    = "${var.project}-${var.env}"
    Project = var.project
    Env     = var.env
  }
}