# Root module — orchestrates the child modules.
# Each module gets added here as its feature branch is merged into `review`.

module "networking" {
  source = "./modules/networking"

  vpc_name     = var.vpc_name
  cluster_name = var.cluster_name
}

module "eks" {
  source = "./modules/eks"

  cluster_name       = var.cluster_name
  vpc_id             = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnet_ids
  public_subnet_ids  = module.networking.public_subnet_ids
}

# Namespace resource managed directly so k8s resources and network policies have a target namespace
resource "kubernetes_namespace" "retail_app" {
  metadata {
    name = var.app_namespace
  }

  depends_on = [module.eks]
}

module "data_layer" {
  source = "./modules/data-layer"

  vpc_id                        = module.networking.vpc_id
  private_subnet_ids            = module.networking.private_subnet_ids
  eks_cluster_security_group_id = module.eks.cluster_security_group_id
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


  depends_on = [module.eks]
}

module "k8s" {
  source = "./modules/k8s"

  namespace           = var.app_namespace
  mysql_secret_arn    = module.data_layer.mysql_secret_arn
  postgres_secret_arn = module.data_layer.postgres_secret_arn

  depends_on = [
    module.eks,
    kubernetes_namespace.retail_app
  ]
}

module "observability" {
  source = "./modules/observability"

  cluster_name      = var.cluster_name
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url

  depends_on = [module.eks]
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

  depends_on = [module.eks]
}

module "cost_guardrails" {
  source = "./modules/cost-guardrails"

  budget_alert_email = var.budget_alert_email
  project_tag        = var.project_tag
}

module "tls" {
  source = "./modules/tls"

  nip_io_host = var.nip_io_host # leave null for the first apply — see modules/tls/variables.tf
}

module "network_policies" {
  source = "./modules/network-policies"

  namespace = var.app_namespace
  vpc_cidr  = module.networking.vpc_cidr

  depends_on = [
    module.eks,
    kubernetes_namespace.retail_app
  ]
}


# module "data_layer"  { source = "./modules/data-layer" ... }  # feature/data-layer
# module "iam"         { source = "./modules/iam" ... }         # feature/security-access
# module "serverless"  { source = "./modules/serverless" ... }  # feature/serverless
