locals {
  tags = { Project = var.project, Environment = "dev" }
}

data "aws_availability_zones" "available" {}
data "aws_caller_identity" "current" {}

# ------------------------------ VPC -------------------------------------------
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.project}-vpc"
  cidr = var.vpc_cidr

  azs             = slice(data.aws_availability_zones.available.names, 0, var.az_count)
  public_subnets  = [for i in range(var.az_count) : cidrsubnet(var.vpc_cidr, 8, i)]
  private_subnets = [for i in range(var.az_count) : cidrsubnet(var.vpc_cidr, 8, i + 10)]

  enable_nat_gateway = true
  single_nat_gateway = true

  # Required tags so ALB controller can choose subnets
  public_subnet_tags = {
    "kubernetes.io/role/elb"                         = "1"
    "kubernetes.io/cluster/${var.project}-eks"       = "shared"
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"                = "1"
    "kubernetes.io/cluster/${var.project}-eks"       = "shared"
  }

  tags = local.tags
}

# ------------------------------ EKS -------------------------------------------
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "${var.project}-eks"
  cluster_version = "1.29"
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnets

  enable_irsa = true

  # Enable public endpoint for Terraform access
  cluster_endpoint_public_access = true
  cluster_endpoint_private_access = true

  eks_managed_node_groups = {
    default = {
      min_size     = var.eks_min_size
      max_size     = var.eks_max_size
      desired_size = var.eks_min_size
      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"
    }
  }

  tags = local.tags
}

# Providers configured in separate file (kubernetes-providers.tf)
# to avoid dependency issues during initial creation

# ------------------------------ ECR -------------------------------------------
module "ecr_frontend" {
  source  = "terraform-aws-modules/ecr/aws"
  version = "~> 2.0"
  repository_name = "${var.project}-frontend"
  
  # Disable lifecycle policy to avoid length validation error
  create_lifecycle_policy = false
  
  tags = local.tags
}

module "ecr_backend" {
  source  = "terraform-aws-modules/ecr/aws"
  version = "~> 2.0"
  repository_name = "${var.project}-backend"
  
  # Disable lifecycle policy to avoid length validation error
  create_lifecycle_policy = false
  
  tags = local.tags
}

# -------------------------- Route53 + ACM (OPTION A: Commented out - using ALB DNS) -----
# resource "aws_route53_zone" "public" {
#   name = var.domain_name
#   tags = local.tags
# }

# module "acm" {
#   source  = "terraform-aws-modules/acm/aws"
#   version = "~> 5.0"
# 
#   domain_name               = var.domain_name
#   zone_id                   = aws_route53_zone.public.zone_id
#   subject_alternative_names = ["*.${var.domain_name}"]
#   wait_for_validation       = true
#   tags = local.tags
# }

# ------------------------------ RDS -------------------------------------------
# SG limited to EKS node SG on 5432
resource "aws_security_group" "rds" {
  name        = "${var.project}-rds-sg"
  description = "Allow Postgres from EKS nodes"
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}

resource "aws_security_group_rule" "rds_from_nodes" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds.id
  source_security_group_id = module.eks.node_security_group_id
}

module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 6.5"

  identifier              = "${var.project}-pg"
  engine                  = "postgres"
  engine_version          = "15"
  instance_class          = var.db_instance_class
  allocated_storage       = 20
  db_name                 = var.db_name
  username                = var.db_username
  manage_master_user_password = true  # stored in Secrets Manager

  # Parameter group family for PostgreSQL 15
  family = "postgres15"
  
  create_db_subnet_group  = true
  subnet_ids              = module.vpc.private_subnets
  vpc_security_group_ids  = [aws_security_group.rds.id]
  publicly_accessible     = false

  tags = local.tags
}

# ------------------------ aws-auth ConfigMap -------------------------
# Add TerraformUser to aws-auth ConfigMap for kubectl access
resource "kubernetes_config_map" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapUsers = yamlencode([
      {
        userarn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/${var.terraform_user_name}"
        username = var.terraform_user_name
        groups   = ["system:masters"]
      }
    ])
  }

  depends_on = [module.eks]
}

# ------------------------ Helm add-ons in ./helm/*.tf -------------------------
# (ALB controller, ExternalDNS, cert-manager, External Secrets, Argo CD)