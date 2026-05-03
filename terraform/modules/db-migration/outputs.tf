output "completion_marker" {
  value       = null_resource.run.id
  description = "Use as a depends_on target for resources that require migrations to be applied."
}

output "task_definition_arn" {
  value       = aws_ecs_task_definition.this.arn
  description = "ARN of the one-shot migration task definition."
}
