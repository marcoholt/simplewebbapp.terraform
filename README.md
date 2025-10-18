# SimpleWebApp – AWS/EKS Terraform (Route53 only)

## Prereqs
- Terraform >= 1.6
- AWS CLI configured
- A domain **already registered in Route 53** (or transferred there)

## Quickstart
cp terraform.tfvars.example terraform.tfvars   # set domain_name
terraform init
terraform apply

## After apply
- Build/push Docker images to ECR repos printed in outputs.
- Point Argo CD at your GitOps repo that deploys:
  - Namespaces: frontend, backend, database
  - Deployments/Services
  - Ingress:
      /     -> frontend svc:80
      /api  -> backend  svc:3001
- ExternalDNS will create app.<your-domain> to the ALB.
- TLS: Use the ACM cert ARN in your app Ingress annotations for ALB.

Notes:
- ALB Ingress Controller requires subnet tags; set by this VPC module.
- cert-manager is installed for future use; ALB uses ACM directly.
