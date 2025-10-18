provider "aws" {
  region = var.region
}

# Kubernetes & Helm providers are configured in main.tf after EKS is created
