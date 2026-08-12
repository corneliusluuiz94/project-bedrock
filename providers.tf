provider "aws" {
  region = var.aws_region

  # Every resource this provider touches automatically gets this tag —
  # satisfies the "all resources must have Project: tinyuka-2025-capstone" rule
  # without you having to remember it in every module.
  default_tags {
    tags = {
      Project = var.project_tag
    }
  }
}

data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_name
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.this.token
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}