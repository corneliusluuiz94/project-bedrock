variable "aws_region" {
  description = "AWS region — must be us-east-1 per assessment constraints"
  type        = string
  default     = "us-east-1"

  validation {
    condition     = var.aws_region == "us-east-1"
    error_message = "Assessment requires us-east-1 (N. Virginia)."
  }
}

variable "project_tag" {
  description = "Mandatory tag value applied to every resource"
  type        = string
  default     = "tinyuka-2025-capstone"
}

variable "cluster_name" {
  description = "EKS cluster name — fixed by grading script"
  type        = string
  default     = "project-bedrock-cluster"
}

variable "vpc_name" {
  description = "VPC Name tag — fixed by grading script"
  type        = string
  default     = "project-bedrock-vpc"
}

variable "app_namespace" {
  description = "Kubernetes namespace for the retail app"
  type        = string
  default     = "retail-app"
}

variable "dev_iam_user" {
  description = "Read-only developer IAM user name"
  type        = string
  default     = "bedrock-dev-view"
}

variable "student_id" {
  description = "Your student ID/name suffix — used to make the assets bucket globally unique"
  type        = string

  validation {
    condition     = length(var.student_id) > 0 && can(regex("^[a-z0-9-]+$", var.student_id))
    error_message = "student_id must be lowercase letters, numbers, or hyphens only (S3 bucket naming rules)."
  }
}

variable "assets_bucket_name" {
  description = "S3 bucket for uploaded product images (Lambda trigger source)"
  type        = string
  default     = null # computed in locals as bedrock-assets-<student_id> if left null
}

variable "lambda_function_name" {
  description = "Lambda function name — fixed by grading script"
  type        = string
  default     = "bedrock-asset-processor"
}
variable "github_repo" {
  description = "GitHub repo in owner/repo format — used to scope the GitHub Actions OIDC trust policy"
  type        = string
  default     = "corneliusluuiz94/project-bedrock" # update if your actual repo name differs
}

variable "budget_alert_email" {
  description = "Email address that receives the AWS Budget alert"
  type        = string
}

variable "nip_io_host" {
  description = "Set on the SECOND apply once you know the ALB's IP — see modules/tls/variables.tf for the two-step process"
  type        = string
  default     = null
}
