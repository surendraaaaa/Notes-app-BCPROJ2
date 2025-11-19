output "vpc_id" {
  value = module.network.vpc_id
}

output "public_subnets" {
  value = module.network.public_subnets
}

output "sg_id" {
  value = module.sg.sg_id
}

output "alb_dns_name" {
  value = module.alb.alb_dns_name
}

output "frontend_target_group_arn" {
  value = module.alb.target_group_arns["frontend"]
}

output "backend_target_group_arn" {
  value = module.alb.target_group_arns["backend"]
}

output "ecs_cluster_name" {
  value = module.ecs_cluster.cluster_name
}

output "frontend_service_name" {
  value = module.ecs_cluster.frontend_service_name
}

output "backend_service_name" {
  value = module.ecs_cluster.backend_service_name
}

output "rds_endpoint" {
  value = aws_db_instance.notes.address
}
