# Amazon CloudWatch Observability EKS add-on — this is what actually satisfies
# "we should be able to see the retail-store-sample-app logs in the CloudWatch
# console" (control plane logging was already handled in modules/eks/main.tf).
#
# ASSUMPTION TO VERIFY (same category as the access_config issue in
# feature/security-access): this add-on is expected to auto-create its own
# namespace (amazon-cloudwatch) and a ServiceAccount named "cloudwatch-agent",
# and the IRSA trust policy below is built against that expected identity.
# If aws_eks_addon.cloudwatch_observability applies successfully but logs
# never appear in CloudWatch, check the actual namespace/SA name with:
#   kubectl get sa -n amazon-cloudwatch
# and adjust the "sub" condition below to match if it differs.

data "aws_iam_policy_document" "observability_assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.oidc_provider_url}:sub"
      values   = ["system:serviceaccount:amazon-cloudwatch:cloudwatch-agent"]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.oidc_provider_url}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "observability" {
  name               = "${var.cluster_name}-observability-role"
  assume_role_policy = data.aws_iam_policy_document.observability_assume.json
}

# AWS-managed policy, exactly what the CloudWatch agent needs — logs, metrics,
# nothing broader.
resource "aws_iam_role_policy_attachment" "observability" {
  role       = aws_iam_role.observability.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_eks_addon" "cloudwatch_observability" {
  cluster_name             = var.cluster_name
  addon_name               = "amazon-cloudwatch-observability"
  service_account_role_arn = aws_iam_role.observability.arn

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
}
