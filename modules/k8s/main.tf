resource "kubernetes_namespace" "retail_app" {
  metadata {
    name = var.namespace
  }
}

# Pull the real credentials from Secrets Manager at apply time — this value never
# lives in any .tf file, any values.yaml, or git history. It only exists in
# Terraform's in-memory plan/apply and in the resulting k8s Secret object.
data "aws_secretsmanager_secret_version" "mysql" {
  secret_id = var.mysql_secret_arn
}

data "aws_secretsmanager_secret_version" "postgres" {
  secret_id = var.postgres_secret_arn
}

locals {
  mysql_creds    = jsondecode(data.aws_secretsmanager_secret_version.mysql.secret_string)
  postgres_creds = jsondecode(data.aws_secretsmanager_secret_version.postgres.secret_string)
}

# Key names must match EXACTLY what the catalog chart's secret.yml template expects
# (confirmed from src/catalog/chart/templates/secret.yaml):
resource "kubernetes_secret" "catalog_db" {
  metadata {
    name      = "catalog-db"
    namespace = kubernetes_namespace.retail_app.metadata[0].name
  }

  data = {
    RETAIL_CATALOG_PERSISTENCE_USER     = local.mysql_creds.username
    RETAIL_CATALOG_PERSISTENCE_PASSWORD = local.mysql_creds.password
  }
}

# Key names confirmed from src/orders/chart/templates/secret-db.yaml — note the
# "_USERNAME" suffix here vs. catalog's "_USER", easy to mismatch if typed by hand.
resource "kubernetes_secret" "orders_db" {
  metadata {
    name      = "orders-db"
    namespace = kubernetes_namespace.retail_app.metadata[0].name
  }

  data = {
    RETAIL_ORDERS_PERSISTENCE_USERNAME = local.postgres_creds.username
    RETAIL_ORDERS_PERSISTENCE_PASSWORD = local.postgres_creds.password
  }
}