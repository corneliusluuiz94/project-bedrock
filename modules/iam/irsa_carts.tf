# IRSA: lets the carts pod's Kubernetes ServiceAccount assume this role directly —
# no AWS keys stored anywhere in the cluster, and scoped to only the operations
# and the single table this service actually needs.
#
# VERIFY: the trust policy below assumes the carts Helm release creates a
# ServiceAccount named "carts" (matches fullnameOverride: carts in cart-values.yaml
# / the umbrella chart's carts: alias). After your first deploy, confirm with:
#   kubectl get sa -n retail-app
# and adjust var.carts_service_account_name if it doesn't match.

variable "carts_service_account_name" {
  description = "Must match the k8s ServiceAccount name the carts pod actually uses — determined by fullnameOverride: carts in cart-values.yaml"
  type        = string
  default     = "carts"
}

variable "oidc_provider_arn" {
  type = string
}

variable "oidc_provider_url" {
  description = "OIDC issuer URL without the https:// prefix"
  type        = string
}

variable "carts_table_arn" {
  type = string
}

data "aws_iam_policy_document" "carts_irsa_assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.oidc_provider_url}:sub"
      values   = ["system:serviceaccount:${var.app_namespace}:${var.carts_service_account_name}"]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.oidc_provider_url}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "carts_irsa" {
  name               = "${var.cluster_name}-carts-dynamodb-role"
  assume_role_policy = data.aws_iam_policy_document.carts_irsa_assume.json
}

# Only the operations the carts service's DynamoDBCartService.java actually calls,
# scoped to the one table and its one GSI — nothing account-wide, nothing broader.
data "aws_iam_policy_document" "carts_dynamodb_access" {
  statement {
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem",
      "dynamodb:Query",
    ]
    resources = [
      var.carts_table_arn,
      "${var.carts_table_arn}/index/*",
    ]
  }
}

resource "aws_iam_role_policy" "carts_dynamodb_access" {
  name   = "${var.cluster_name}-carts-dynamodb-policy"
  role   = aws_iam_role.carts_irsa.id
  policy = data.aws_iam_policy_document.carts_dynamodb_access.json
}

output "carts_irsa_role_arn" {
  value = aws_iam_role.carts_irsa.arn
}
