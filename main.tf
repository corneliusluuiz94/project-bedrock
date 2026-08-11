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

module "data_layer" {
  source = "./modules/data-layer"

  vpc_id                         = module.networking.vpc_id
  private_subnet_ids             = module.networking.private_subnet_ids
  eks_cluster_security_group_id  = module.eks.cluster_security_group_id
}

module "iam" {
  source = "./modules/iam"

  dev_iam_user      = var.dev_iam_user
  cluster_name      = var.cluster_name
  app_namespace     = var.app_namespace
  assets_bucket_arn = "arn:aws:s3:::${local.assets_bucket_name}" # bucket itself is created in feature/serverless
}




# module "data_layer"  { source = "./modules/data-layer" ... }  # feature/data-layer
# module "iam"         { source = "./modules/iam" ... }         # feature/security-access
# module "serverless"  { source = "./modules/serverless" ... }  # feature/serverless
