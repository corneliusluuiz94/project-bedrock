variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "kubernetes_version" {
  description = "EKS Kubernetes version — must be the oldest actively-supported version at deploy time. Check https://docs.aws.amazon.com/eks/latest/userguide/kubernetes-versions-standard.html before changing."
  type        = string
  default     = "1.34" # oldest in standard support as of Aug 2026 (1.33 left standard support Jul 29 2026)
}

variable "vpc_id" {
  description = "VPC ID from the networking module"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs — nodes and the cluster's ENIs live here"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "Public subnet IDs — needed so the API server endpoint can also route through them if public access is enabled"
  type        = list(string)
}

variable "node_instance_type" {
  description = "EC2 instance type for the managed node group"
  type        = string
  default     = "t3.medium"
}

variable "node_desired_size" {
  type    = number
  default = 2
}

variable "node_min_size" {
  type    = number
  default = 2
}

variable "node_max_size" {
  type    = number
  default = 4
}
