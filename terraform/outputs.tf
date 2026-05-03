
output "public_alb_url" {
  value       = "http://${module.alb_public.dns_name}"
  description = "Public ALB URL — open in browser."
}

output "internal_alb_dns_name" {
  value       = module.alb_internal.dns_name
  description = "Internal ALB hostname (extractor + parser)."
}


output "github_deploy_role_arn" {
  value       = module.github_deploy_role.arn
  description = "Configure GitHub secret AWS_ROLE_ARN with this value."
}

output "ecr_repositories" {
  value       = { for k, m in module.ecr : k => m.repository_url }
  description = "ECR repository URLs by service key."
}


output "ecs_cluster_name" {
  value       = module.ecs_cluster.name
  description = "ECS cluster name (handy for CLI commands)."
}

output "rds_endpoint" {
  value       = module.rds.db_instance_endpoint
  description = "RDS endpoint (host:port)."
  sensitive   = true
}

output "kms_key_arn" {
  value       = module.kms.key_arn
  description = "Stack-wide CMK ARN."
}

output "ops_sns_topic_arn" {
  value       = aws_sns_topic.ops.arn
  description = "Subscribe additional endpoints (Slack, PagerDuty) to this topic."
}
