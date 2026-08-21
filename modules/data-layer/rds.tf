# ---------- Generated credentials (never hand-typed, never committed) ----------
resource "random_password" "mysql" {
  length  = 20
  special = false # Helm/JDBC connection strings choke on some special chars — keep it simple and still strong
}

resource "random_password" "postgres" {
  length  = 20
  special = false
}

# ---------- MySQL (Catalog service) ----------
resource "aws_db_instance" "mysql" {
  identifier     = "${var.project_prefix}-catalog-mysql"
  engine         = "mysql"
  engine_version = "8.0"
  instance_class = var.db_instance_class

  allocated_storage = 20
  storage_type      = "gp3"

  db_name  = "catalog"
  username = "catalog_admin"
  password = random_password.mysql.result

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.mysql.id]
  publicly_accessible    = false # private subnet only, per assessment security requirement

  multi_az                = false # single-AZ is sufficient and preferred for cost, per assessment
  backup_retention_period = var.backup_retention_days
  skip_final_snapshot     = true # fine for an assessment; would be false in real prod

  tags = { Name = "${var.project_prefix}-catalog-mysql" }
}

# ---------- PostgreSQL (Orders service) ----------
resource "aws_db_instance" "postgres" {
  identifier     = "${var.project_prefix}-orders-postgres"
  engine         = "postgres"
  engine_version = "16"
  instance_class = var.db_instance_class

  allocated_storage = 20
  storage_type      = "gp3"

  db_name  = "orders"
  username = "orders_admin"
  password = random_password.postgres.result

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.postgres.id]
  publicly_accessible    = false

  multi_az                = false
  backup_retention_period = var.backup_retention_days
  skip_final_snapshot     = true

  tags = { Name = "${var.project_prefix}-orders-postgres" }
}
