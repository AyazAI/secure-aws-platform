output "alb_dns_name" {
  description = "Public DNS name of the load balancer. This is the demo URL after an apply."
  value       = module.alb.alb_dns_name
}

output "ecr_repository_url" {
  description = "Private repository URL for sample-app."
  value       = module.ecs.repository_url
}

output "ecs_cluster_name" {
  description = "ECS cluster name."
  value       = module.ecs.cluster_name
}

output "dashboard_name" {
  description = "CloudWatch dashboard name."
  value       = module.monitoring.dashboard_name
}

output "budget_name" {
  description = "Monthly cost budget name."
  value       = module.budget.budget_name
}

output "kms_key_arn" {
  description = "Customer managed key ARN."
  value       = module.kms.key_arn
}
