# ---------- bedrock-dev-view IAM user ----------
resource "aws_iam_user" "dev_view" {
  name = var.dev_iam_user
}

# Console access: broad read-only across the account — can view but not modify anything.
resource "aws_iam_user_policy_attachment" "readonly" {
  user       = aws_iam_user.dev_view.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# Scoped exception: this user can also PutObject to the assets bucket ONLY —
# needed so the grader can upload a test image and trigger the Lambda (section 4.5).
data "aws_iam_policy_document" "assets_put_object" {
  statement {
    sid       = "AllowPutObjectToAssetsBucketOnly"
    actions   = ["s3:PutObject"]
    resources = ["${var.assets_bucket_arn}/*"]
  }
}

resource "aws_iam_user_policy" "assets_put_object" {
  name   = "${var.dev_iam_user}-assets-put-object"
  user   = aws_iam_user.dev_view.name
  policy = data.aws_iam_policy_document.assets_put_object.json
}

# Programmatic access — grading needs Access Key ID + Secret.
# NOTE: rotate/deactivate this key once grading is complete (per assessment instructions).
resource "aws_iam_access_key" "dev_view" {
  user = aws_iam_user.dev_view.name
}

# Console access — auto-generated password, forces reset on first login.
resource "aws_iam_user_login_profile" "dev_view" {
  user                    = aws_iam_user.dev_view.name
  password_reset_required = true
}

# ---------- Kubernetes access via EKS Access Entries (not aws-auth ConfigMap) ----------
resource "aws_eks_access_entry" "dev_view" {
  cluster_name  = var.cluster_name
  principal_arn = aws_iam_user.dev_view.arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "dev_view_namespace_view" {
  cluster_name  = var.cluster_name
  principal_arn = aws_iam_user.dev_view.arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"

  access_scope {
    type       = "namespace"
    namespaces = [var.app_namespace] # scoped to retail-app only — not cluster-wide 
  }
}
