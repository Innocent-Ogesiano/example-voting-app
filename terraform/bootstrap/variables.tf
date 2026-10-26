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
  description = "GitHub repository (org/repo) allowed to assume the CI role via OIDC"
  type        = string
  default     = "Innocent-Ogesiano/example-voting-app"
}

variable "github_repository_id" {
  description = "Immutable numeric GitHub repository ID (GET /repos/{owner}/{repo} -> .id), used to match the OIDC token's repository_id claim regardless of repo renames"
  type        = string
  default     = "1414155645"
}

variable "hcp_organization" {
  description = "HCP Terraform organization whose runs may assume the Terraform IAM role"
  type        = string
  default     = "ts-academy"
}

variable "hcp_workspace" {
  description = "HCP Terraform workspace (main stack) whose runs may assume the Terraform IAM role"
  type        = string
  default     = "example-voting-app-eks"
}
