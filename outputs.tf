output "cluster_name"     { value = module.eks.cluster_name }
output "cluster_endpoint" { value = module.eks.cluster_endpoint }
# output "route53_zone_id"  { value = aws_route53_zone.public.zone_id }  # OPTION A: Commented out
output "rds_endpoint"     { value = module.rds.db_instance_endpoint }
output "ecr_frontend"     { value = module.ecr_frontend.repository_url }
output "ecr_backend"      { value = module.ecr_backend.repository_url }
