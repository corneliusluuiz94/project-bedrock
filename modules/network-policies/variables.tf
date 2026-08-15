variable "namespace" {
  type    = string
  default = "retail-app"
}

variable "vpc_cidr" {
  description = "Used to allow egress from catalog/orders to RDS, which lives at a private VPC IP"
  type        = string
}