output "mysql_endpoint" {
  value = aws_db_instance.mysql.address
}

output "mysql_secret_arn" {
  value = aws_secretsmanager_secret.mysql.arn
}

output "postgres_endpoint" {
  value = aws_db_instance.postgres.address
}

output "postgres_secret_arn" {
  value = aws_secretsmanager_secret.postgres.arn
}

output "carts_table_name" {
  value = aws_dynamodb_table.carts.name
}

output "carts_table_arn" {
  value = aws_dynamodb_table.carts.arn
}
