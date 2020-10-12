module "vpc" {
  source  = "punkerside/vpc/aws"
  version = "0.0.8"

  project = var.project
  env     = var.env
}

module "eks" {
  source  = "punkerside/eks/aws"
  version = "0.0.2"

  project            = var.project
  env                = var.env
  subnet_private_ids = module.vpc.subnet_private_ids
  subnet_public_ids  = module.vpc.subnet_public_ids
}