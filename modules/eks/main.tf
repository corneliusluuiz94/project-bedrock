# ---------- EKS Cluster ----------
resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  role_arn = aws_iam_role.cluster.arn
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids              = concat(var.private_subnet_ids, var.public_subnet_ids)
    endpoint_private_access = true
    endpoint_public_access  = true # kept open for kubectl from your machine during the assessment; tighten for real prod
  }


  # Required for EKS Access Entries (used in feature/security-access) to work.
  # API_AND_CONFIG_MAP keeps the legacy aws-auth ConfigMap path available too,
  # even though this project doesn't use it — purely additive, no disruption.
  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }
  # Control plane logging (assessment section 4.4) — ships to CloudWatch automatically,
  # no extra add-on needed for these five log types.


  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  depends_on = [
    aws_iam_role_policy_attachment.cluster_policy
  ]
}

# ---------- OIDC provider (required for IRSA — IAM Roles for Service Accounts) ----------
# Needed later by the AWS Load Balancer Controller, Cluster Autoscaler, and the
# CloudWatch Observability add-on, all of which authenticate via IRSA rather than
# broad node-level permissions.
data "tls_certificate" "eks_oidc" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks_oidc.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

# ---------- Managed Node Group ----------
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.cluster_name}-nodes"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = var.private_subnet_ids # nodes live in private subnets only

  instance_types = [var.node_instance_type]
  ami_type       = "AL2023_x86_64_STANDARD" # AL2 is not offered as of EKS 1.33+

  scaling_config {
    desired_size = var.node_desired_size
    min_size     = var.node_min_size
    max_size     = var.node_max_size
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.node_worker_policy,
    aws_iam_role_policy_attachment.node_cni_policy,
    aws_iam_role_policy_attachment.node_ecr_readonly,
  ]
}

# ---------- EKS Access Entry for CI/CD Pipeline ----------
resource "aws_eks_access_entry" "github_actions" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = "arn:aws:iam::316762121840:role/project-bedrock-cluster-github-actions-role"
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "github_actions_admin" {
  cluster_name  = aws_eks_cluster.main.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = "arn:aws:iam::316762121840:role/project-bedrock-cluster-github-actions-role"

  access_scope {
    type = "cluster"
  }
}
