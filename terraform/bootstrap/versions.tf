terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  cloud {
    organization = "ts-academy"

    workspaces {
      name = "example-voting-app-bootstrap"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
