# One SG per engine so each only opens the port it actually needs.

resource "aws_security_group" "mysql" {
  name        = "${var.project_prefix}-mysql-sg"
  description = "Allow MySQL (catalog) traffic only from EKS pods/nodes"
  vpc_id      = var.vpc_id

  ingress {
    description     = "MySQL from EKS cluster only"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [var.eks_cluster_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_prefix}-mysql-sg" }
}

resource "aws_security_group" "postgres" {
  name        = "${var.project_prefix}-postgres-sg"
  description = "Allow PostgreSQL (orders) traffic only from EKS pods/nodes"
  vpc_id      = var.vpc_id

  ingress {
    description     = "PostgreSQL from EKS cluster only"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.eks_cluster_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_prefix}-postgres-sg" }
}

resource "aws_db_subnet_group" "main" {
  name       = "${var.project_prefix}-db-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = { Name = "${var.project_prefix}-db-subnet-group" }
}
