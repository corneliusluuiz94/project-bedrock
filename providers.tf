provider "aws" {
  region = var.aws_region

  # Every resource this provider touches automatically gets this tag —
  # satisfies the "all resources must have Project: tinyuka-2025-capstone" rule
  # without you having to remember it in every module.
  default_tags {
    tags = {
      Project = var.project_tag
    }
  }
}