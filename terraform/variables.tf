variable "aws_region" {
  description = "AWS region to deploy the EKS cluster into"
  type        = string
  default     = "us-west-2"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "example-voting-app"
}

variable "kubernetes_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.34"
}

variable "node_instance_type" {
  description = "EC2 instance type for worker nodes"
  type        = string
  default     = "t3.medium"
}

variable "node_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 2
}

variable "github_repository" {
  description = "GitHub repository (org/repo) allowed to assume the CI role via OIDC"
  type        = string
  default     = "Innocent-Ogesiano/example-voting-app"
}

variable "tfstate_bucket" {
  description = "S3 bucket holding Terraform remote state"
  type        = string
  default     = "example-voting-app-tfstate-385685326245"
}
