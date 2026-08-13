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

  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url
  carts_table_arn   = module.data_layer.carts_table_arn
}

module "k8s" {
  source = "./modules/k8s"

  namespace           = var.app_namespace
  mysql_secret_arn    = module.data_layer.mysql_secret_arn
  postgres_secret_arn = module.data_layer.postgres_secret_arn
}

module "observability" {
  source = "./modules/observability"

  cluster_name       = var.cluster_name
  oidc_provider_arn  = module.eks.oidc_provider_arn
  oidc_provider_url  = module.eks.oidc_provider_url
}

module "serverless" {
  source = "./modules/serverless"

  assets_bucket_name   = local.assets_bucket_name
  lambda_function_name = var.lambda_function_name
}

module "cicd" {
  source = "./modules/cicd"

  github_repo  = var.github_repo
  cluster_name = var.cluster_name
}

# module "data_layer"  { source = "./modules/data-layer" ... }  # feature/data-layer
# module "iam"         { source = "./modules/iam" ... }         # feature/security-access
# module "serverless"  { source = "./modules/serverless" ... }  # feature/serverless
