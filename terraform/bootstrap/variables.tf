variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "cluster_name" {
  description = "Name used as a prefix for the GitHub Actions IAM role (must match the main stack's cluster_name)"
  type        = string
  default     = "example-voting-app"
}

variable "github_repository" {
  description = "GitHub repository (owner/repo) allowed to assume the CI role via OIDC"
  type        = string
}

variable "hcp_organization" {
  description = "HCP Terraform organization whose runs may assume the Terraform IAM role"
  type        = string
}

variable "hcp_workspace" {
  description = "HCP Terraform workspace (main stack) whose runs may assume the Terraform IAM role (must match TF_WORKSPACE for the main stack)"
  type        = string
  default     = "example-voting-app-eks"
}
