locals {
  assets_bucket_name = coalesce(var.assets_bucket_name, "bedrock-assets-${var.student_id}")
}
