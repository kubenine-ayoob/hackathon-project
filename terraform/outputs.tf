output "public_alb_url" {
  value       = "http://${aws_lb.public.dns_name}"
  description = "Open in browser"
}

output "github_deploy_role_arn" {
  value       = aws_iam_role.github_deploy.arn
  description = "Set GitHub secret AWS_ROLE_ARN to this"
}

output "ecr_repositories" {
  value = { for k, v in aws_ecr_repository.app : k => v.repository_url }
}