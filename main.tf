# Root module — orchestrates the child modules.
# Each module gets added here as its feature branch is merged into `review`.

module "networking" {
  source = "./modules/networking"

  vpc_name     = var.vpc_name
  cluster_name = var.cluster_name
}

module "eks" {
  source = "./modules/eks"

  cluster_name        = var.cluster_name
  vpc_id              = module.networking.vpc_id
  private_subnet_ids  = module.networking.private_subnet_ids
  public_subnet_ids   = module.networking.public_subnet_ids
}



# module "eks"         { source = "./modules/eks" ... }         # feature/eks-cluster
# module "data_layer"  { source = "./modules/data-layer" ... }  # feature/data-layer
# module "iam"         { source = "./modules/iam" ... }         # feature/security-access
# module "serverless"  { source = "./modules/serverless" ... }  # feature/serverless
