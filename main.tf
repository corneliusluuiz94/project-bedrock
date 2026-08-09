# Root module — orchestrates the child modules.
# Each module gets added here as its feature branch is merged into `review`.

module "networking" {
  source = "./modules/networking"

  vpc_name     = var.vpc_name
  cluster_name = var.cluster_name
}

# module "eks"         { source = "./modules/eks" ... }         # feature/eks-cluster
# module "data_layer"  { source = "./modules/data-layer" ... }  # feature/data-layer
# module "iam"         { source = "./modules/iam" ... }         # feature/security-access
# module "serverless"  { source = "./modules/serverless" ... }  # feature/serverless
