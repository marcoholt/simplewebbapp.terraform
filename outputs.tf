output "cluster_name"     { value = data.aws_eks_cluster.existing.name }
output "cluster_endpoint" { value = data.aws_eks_cluster.existing.endpoint }
output "rds_endpoint"     { value = module.rds.db_instance_endpoint }
output "ecr_frontend"     { value = module.ecr_frontend.repository_url }
output "ecr_backend"      { value = module.ecr_backend.repository_url }