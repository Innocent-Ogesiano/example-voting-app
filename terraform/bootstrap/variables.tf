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

variable "tfstate_bucket" {
  description = "S3 bucket holding Terraform remote state (for both this bootstrap stack and the main stack)"
  type        = string
  default     = "example-voting-app-tfstate-385685326245"
}
