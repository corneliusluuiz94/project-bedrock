variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  description = "Private subnets for the RDS subnet group"
  type        = list(string)
}

variable "eks_cluster_security_group_id" {
  description = "Only this security group is allowed to reach the databases"
  type        = string
}

variable "project_prefix" {
  description = "Prefix for resource names, e.g. project-bedrock"
  type        = string
  default     = "project-bedrock"
}

variable "db_instance_class" {
  type    = string
  default = "db.t3.micro" # single-instance, single-AZ per assessment cost guidance
}

variable "backup_retention_days" {
  description = "RDS automated backup retention — bonus objective 5.5 wants > 0"
  type        = number
  default     = 3
}

variable "carts_table_name" {
  type    = string
  default = "carts-items"
}
