terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Organization and workspace come from the environment so the repo isn't tied
  # to one HCP account: TF_CLOUD_ORGANIZATION and TF_WORKSPACE.
  cloud {}
}

provider "aws" {
  region = var.aws_region
}
