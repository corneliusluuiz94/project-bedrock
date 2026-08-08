# Root module — orchestrates the child modules.
# Each module gets added here as its feature branch is merged into `review`.
#
# module "networking" { source = "./modules/networking" ... }   # feature/networking
# module "eks"         { source = "./modules/eks" ... }         # feature/eks-cluster
# module "data_layer"  { source = "./modules/data-layer" ... }  # feature/data-layer
# module "iam"         { source = "./modules/iam" ... }         # feature/security-access
# module "serverless"  { source = "./modules/serverless" ... }  # feature/serverless
