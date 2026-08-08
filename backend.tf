# Remote state - S3 backend with native locking (use_lockfile), no DynamoDB table needed.
# NOTE: This S3 bucket must exist BEFORE you run `terraform init`. Terraform cannot
# create the bucket that stores its own state. Create it manually once (see README
# "Bootstrap" section), then fill in the bucket name below.

terraform {
  backend "s3" {
    bucket       = "bedrock-tfstate-alt-soe-tin-025-0310" # e.g. bedrock-tfstate-<your-student-id>
    key          = "project-bedrock/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
    encrypt      = true
  }
}