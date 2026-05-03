terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
}

variable "health_check_grace_period_seconds" {
  type        = number
  description = "Seconds ECS ignores ALB health checks after task start, so slow-booting apps don't get killed."
  default     = 60
}

module "this" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "~> 5.11"

  name        = var.name
  cluster_arn = var.cluster_arn

  cpu           = var.cpu
  memory        = var.memory
  desired_count = var.desired_count

  enable_execute_command = var.enable_execute_command

  create_security_group = false
  security_group_ids    = var.security_group_ids
  subnet_ids            = var.subnet_ids

  load_balancer = {
    primary = {
      target_group_arn = var.target_group_arn
      container_name   = var.container_name
      container_port   = var.container_port
    }
  }


  health_check_grace_period_seconds = var.health_check_grace_period_seconds

  container_definitions = {
    (var.container_name) = {
      cpu       = var.cpu
      memory    = var.memory
      essential = true
      image     = var.image

      port_mappings = [
        { name = "http", containerPort = var.container_port, protocol = "tcp" }
      ]

      environment = var.environment
      secrets     = var.secrets

      readonly_root_filesystem               = var.readonly_root_filesystem
      enable_cloudwatch_logging              = true
      cloudwatch_log_group_retention_in_days = var.log_retention_in_days
    }
  }

  task_exec_secret_arns = var.task_exec_secret_arns

  task_exec_iam_statements = [{
    sid       = "KmsForSecrets"
    actions   = ["kms:Decrypt", "kms:DescribeKey"]
    resources = [var.kms_key_arn]
  }]

  tasks_iam_role_statements = var.tasks_iam_role_statements

  enable_autoscaling       = var.enable_autoscaling
  autoscaling_min_capacity = var.autoscaling_min_capacity
  autoscaling_max_capacity = var.autoscaling_max_capacity
  autoscaling_policies = var.enable_autoscaling ? {
    cpu = {
      policy_type = "TargetTrackingScaling"
      target_tracking_scaling_policy_configuration = {
        predefined_metric_specification = {
          predefined_metric_type = "ECSServiceAverageCPUUtilization"
        }
        target_value       = var.autoscaling_cpu_target
        scale_in_cooldown  = 120
        scale_out_cooldown = 60
      }
    }
  } : {}

  depends_on = [var.depends_on_resources]
}
