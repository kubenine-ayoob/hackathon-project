################################################################################
# moved {} blocks
#
# These tell Terraform "this resource was renamed — don't destroy + recreate it,
# just update state." They have no AWS effect; they're pure state surgery.
#
# Safe to delete after a successful `terraform plan` shows no moves remaining.
################################################################################


moved {
  from = module.ecs_main_backend
  to   = module.ecs_services["main-backend"].module.this
}

moved {
  from = module.ecs_extractor
  to   = module.ecs_services["extractor"].module.this
}

moved {
  from = module.ecs_parser
  to   = module.ecs_services["parser"].module.this
}


moved {
  from = aws_ssm_parameter.db_host
  to   = aws_ssm_parameter.this["db-host"]
}

moved {
  from = aws_ssm_parameter.db_name
  to   = aws_ssm_parameter.this["db-name"]
}

moved {
  from = aws_ssm_parameter.db_user
  to   = aws_ssm_parameter.this["db-user"]
}

moved {
  from = aws_ssm_parameter.s3_bucket
  to   = aws_ssm_parameter.this["s3-bucket"]
}

moved {
  from = aws_ssm_parameter.extractor_url
  to   = aws_ssm_parameter.this["extractor-url"]
}

moved {
  from = aws_ssm_parameter.parser_url
  to   = aws_ssm_parameter.this["parser-url"]
}

moved {
  from = aws_ssm_parameter.main_backend_url
  to   = aws_ssm_parameter.this["main-backend-url"]
}

# DB migration moved into modules/db-migration.
moved {
  from = aws_cloudwatch_log_group.db_migrate
  to   = module.db_migration.aws_cloudwatch_log_group.this
}

moved {
  from = aws_iam_role.db_migrate_exec
  to   = module.db_migration.aws_iam_role.exec
}

moved {
  from = aws_iam_role_policy_attachment.db_migrate_exec_managed
  to   = module.db_migration.aws_iam_role_policy_attachment.exec_managed
}

moved {
  from = aws_iam_role.db_migrate_task
  to   = module.db_migration.aws_iam_role.task
}

moved {
  from = aws_iam_role_policy.db_migrate_task
  to   = module.db_migration.aws_iam_role_policy.task_s3_read
}

moved {
  from = aws_ecs_task_definition.db_migrate
  to   = module.db_migration.aws_ecs_task_definition.this
}

moved {
  from = null_resource.db_migrate_run
  to   = module.db_migration.null_resource.run
}


moved {
  from = aws_security_group_rule.ecs_tasks_from_internal_alb["8001"]
  to   = aws_security_group_rule.ecs_tasks_from_internal_alb["extractor"]
}

moved {
  from = aws_security_group_rule.ecs_tasks_from_internal_alb["8002"]
  to   = aws_security_group_rule.ecs_tasks_from_internal_alb["parser"]
}
