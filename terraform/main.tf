module "vpc" {
  source  = "punkerside/vpc/aws"
  version = "0.0.4"

  name = var.name == null ? random_string.main.result : var.name
}

module "eks" {
  source  = "punkerside/eks/aws"
  version = "0.0.1"

  name               = var.name == null ? random_string.main.result : var.name
  eks_version        = var.eks_version
  subnet_private_ids = module.vpc.subnet_private_ids.*.id
  subnet_public_ids  = module.vpc.subnet_public_ids.*.id
}