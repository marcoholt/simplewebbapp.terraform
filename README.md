# SimpleWebApp – AWS/EKS Terraform (OPTION A: ALB DNS)

## Prereqs
- Terraform >= 1.6
- AWS CLI configured
- **No domain required** - uses ALB's AWS DNS

## Quickstart
terraform init
terraform apply

## After apply
- Build/push Docker images to ECR repos printed in outputs
- Deploy your app with the example Ingress:
  ```bash
  kubectl apply -f ingress-example.yaml
  ```
- Get your ALB URL:
  ```bash
  kubectl get ingress -n frontend
  # Look at ADDRESS column -> your ALB DNS name
  ```
- Access your app at: `http://k8s-simplewebapp-abc123.us-east-2.elb.amazonaws.com`

## What's included
- EKS cluster with ALB Ingress Controller
- ECR repositories for frontend/backend images
- RDS PostgreSQL database
- Argo CD for GitOps (optional)
- **HTTP only** - no TLS/certificates needed

Notes:
- ALB Ingress Controller requires subnet tags; set by this VPC module
- ExternalDNS and Route53 are commented out (Option A approach)
