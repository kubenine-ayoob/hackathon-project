output "service_name" {
  value       = module.this.name
  description = "ECS service name."
}

output "task_definition_arn" {
  value       = module.this.task_definition_arn
  description = "Active task definition ARN."
}

output "tasks_iam_role_arn" {
  value       = module.this.tasks_iam_role_arn
  description = "ARN of the task role (use to add cross-stack permissions)."
}
