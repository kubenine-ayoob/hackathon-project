variable "name" {
  type        = string
  description = "Full ECS service name (already prefixed)."
}

variable "cluster_arn" {
  type        = string
  description = "ARN of the ECS cluster the service runs in."
}

variable "container_name" {
  type        = string
  description = "Primary container name (used for the load balancer mapping)."
}

variable "container_port" {
  type        = number
  description = "Container port exposed to the load balancer."
}

variable "image" {
  type        = string
  description = "Full container image reference, e.g. 12345.dkr.ecr.us-east-1.amazonaws.com/foo:abc123."
}

variable "cpu" {
  type        = number
  description = "Task CPU units."
  default     = 512
}

variable "memory" {
  type        = number
  description = "Task memory (MiB)."
  default     = 1024
}

variable "desired_count" {
  type        = number
  description = "Desired running task count."
  default     = 1
}

variable "subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs for awsvpc networking."
}

variable "security_group_ids" {
  type        = list(string)
  description = "Pre-created security groups attached to the tasks."
}

variable "target_group_arn" {
  type        = string
  description = "ALB target group ARN for the primary container."
}

variable "environment" {
  type        = list(object({ name = string, value = string }))
  description = "Plain environment variables for the container."
  default     = []
}

variable "secrets" {
  type        = list(object({ name = string, valueFrom = string }))
  description = "Secret references (SSM parameter / Secrets Manager ARN) injected as env vars."
  default     = []
}

variable "task_exec_secret_arns" {
  type        = list(string)
  description = "ARNs the execution role is allowed to read for `secrets` injection."
  default     = []
}

variable "kms_key_arn" {
  type        = string
  description = "KMS key used by SSM SecureString / Secrets Manager (allows Decrypt)."
}

variable "tasks_iam_role_statements" {
  type        = any
  description = "Extra IAM statements for the task role (passed through to upstream module)."
  default     = []
}

variable "enable_autoscaling" {
  type        = bool
  description = "Whether to register CPU target-tracking autoscaling."
  default     = false
}

variable "autoscaling_min_capacity" {
  type    = number
  default = 1
}

variable "autoscaling_max_capacity" {
  type    = number
  default = 4
}

variable "autoscaling_cpu_target" {
  type        = number
  description = "Target CPU utilization percentage for scaling."
  default     = 60
}

variable "log_retention_in_days" {
  type        = number
  description = "CloudWatch log retention for the auto-created log group."
  default     = 14
}

variable "enable_execute_command" {
  type        = bool
  description = "Enable ECS Exec for live debugging (disable in prod)."
  default     = false
}

variable "readonly_root_filesystem" {
  type        = bool
  description = "Mount the container root filesystem read-only."
  default     = true
}

variable "depends_on_resources" {
  type        = list(any)
  description = "Resources this service must wait for (e.g. DB migration)."
  default     = []
}
