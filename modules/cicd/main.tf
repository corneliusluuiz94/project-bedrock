# GitHub's OIDC provider — lets GitHub Actions assume an AWS role with short-lived
# tokens instead of long-lived access keys stored as repo secrets.
#data "tls_certificate" "github" {
  #url = "https://token.actions.githubusercontent.com/.well-known/openid-configuration"
#}

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd"
  ]
}

data "aws_iam_policy_document" "github_actions_assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Scoped to this exact repo — any branch/PR within it can assume the role,
    # but no other GitHub repo can, even if they somehow knew the role ARN.
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_repo}:*"]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name               = "${var.cluster_name}-github-actions-role"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume.json
}

# NOTE — deliberate scope decision: this pipeline provisions VPC, EKS, IAM roles,
# RDS, DynamoDB, S3, Lambda, and CloudWatch resources in one apply, and Terraform
# itself needs to create/manage IAM roles as part of that (cluster role, node
# role, bedrock-dev-view, IRSA roles). A tightly least-privilege CI policy would
# need to be re-scoped every time a new resource type gets added in a later
# feature branch, which defeats a lot of the point for a project still being
# built out phase by phase. AdministratorAccess is used here as a pragmatic
# choice for the duration of the assessment — for a real production pipeline,
# you'd narrow this to exactly the services/actions in use once the design is
# stable.
resource "aws_iam_role_policy_attachment" "github_actions_admin" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

output "github_actions_role_arn" {
  value = aws_iam_role.github_actions.arn
}
