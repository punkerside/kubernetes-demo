module "vpc" {
  source  = "punkerside/vpc/aws"
  version = "0.0.9"

  name = var.name == null ? random_string.this.result : var.name
}

module "eks" {
  source  = "punkerside/eks/aws"
  version = "0.0.5"

  name               = var.name == null ? random_string.this.result : var.name
  subnet_private_ids = module.vpc.subnet_private_ids
  subnet_public_ids  = module.vpc.subnet_public_ids
}