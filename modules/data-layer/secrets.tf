# Credentials live only here — the app pulls them at runtime via the External
# Secrets Operator or the Secrets Manager CSI driver (wired up in feature/app-deployment).
# Nothing here ever gets written into a Helm values.yaml that's committed to git.

resource "aws_secretsmanager_secret" "mysql" {
  name        = "${var.project_prefix}/catalog/mysql"
  description = "Catalog service MySQL credentials"
}

resource "aws_secretsmanager_secret_version" "mysql" {
  secret_id = aws_secretsmanager_secret.mysql.id
  secret_string = jsonencode({
    username = aws_db_instance.mysql.username
    password = random_password.mysql.result
    host     = aws_db_instance.mysql.address
    port     = aws_db_instance.mysql.port
    dbname   = aws_db_instance.mysql.db_name
  })
}

resource "aws_secretsmanager_secret" "postgres" {
  name        = "${var.project_prefix}/orders/postgres"
  description = "Orders service PostgreSQL credentials"
}

resource "aws_secretsmanager_secret_version" "postgres" {
  secret_id = aws_secretsmanager_secret.postgres.id
  secret_string = jsonencode({
    username = aws_db_instance.postgres.username
    password = random_password.postgres.result
    host     = aws_db_instance.postgres.address
    port     = aws_db_instance.postgres.port
    dbname   = aws_db_instance.postgres.db_name
  })
}
