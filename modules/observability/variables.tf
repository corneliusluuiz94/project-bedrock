variable "cluster_name" {
  type = string
}

variable "oidc_provider_arn" {
  type = string
}

variable "oidc_provider_url" {
  description = "OIDC issuer URL without the https:// prefix"
  type        = string
}
