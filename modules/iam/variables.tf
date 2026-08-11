variable "dev_iam_user" {
  description = "Read-only developer IAM user name"
  type        = string
}

variable "cluster_name" {
  type = string
}

variable "app_namespace" {
  description = "Namespace this user's Kubernetes view access is scoped to"
  type        = string
}

variable "assets_bucket_arn" {
  description = "ARN of the S3 assets bucket — the dev user gets PutObject scoped to only this bucket"
  type        = string
}
