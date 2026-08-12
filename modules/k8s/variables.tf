variable "namespace" {
  type    = string
  default = "retail-app"
}

variable "mysql_secret_arn" {
  description = "Secrets Manager ARN holding the catalog MySQL credentials (from data-layer module)"
  type        = string
}

variable "postgres_secret_arn" {
  description = "Secrets Manager ARN holding the orders PostgreSQL credentials (from data-layer module)"
  type        = string
}
