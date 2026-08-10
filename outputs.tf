# Only the five required, non-sensitive outputs live here.
# Do NOT add anything sensitive (DB passwords, IAM secrets) — `terraform output -json`
# prints sensitive values in full regardless of the `sensitive = true` flag.

output "cluster_endpoint" {
  description = "EKS cluster API endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name

}

output "region" {
  description = "AWS region"
  value       = var.aws_region
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.networking.vpc_id
}

output "assets_bucket_name" {
  description = "S3 bucket receiving product image uploads"
  value       = local.assets_bucket_name
}
