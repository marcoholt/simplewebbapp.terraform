terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-2"
  # AWS credentials should be configured via environment variables or AWS CLI
  # access_key = var.aws_access_key
  # secret_key = var.aws_secret_key
}