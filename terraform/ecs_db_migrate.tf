
resource "aws_ecs_task_definition" "db_migrate" {
  family                   = "${var.name_prefix}-db-migrate"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.db_migrate_task.arn

  container_definitions = jsonencode([{
    name      = "db-migrate"
    image     = "public.ecr.aws/docker/library/postgres:15"
    essential = true
    command = [
      "bash", "-lc",
      join(" && ", [
        "apt-get update -qq",
        "DEBIAN_FRONTEND=noninteractive apt-get install -y -qq awscli",
        "aws s3 cp 's3://${aws_s3_bucket.db_init.id}/init.sql' /tmp/init.sql",
        "PGPASSWORD='${random_password.db.result}' psql -h '${aws_db_instance.postgres.address}' -U '${var.db_user}' -d '${var.db_name}' -f /tmp/init.sql",
        "echo db_init_ok",
      ])
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.db_migrate.name
        awslogs-region        = var.aws_region
        awslogs-stream-prefix = "ecs"
      }
    }
  }])
}

resource "null_resource" "db_migrate_run" {
  depends_on = [
    aws_ecs_cluster.main,
    aws_db_instance.postgres,
    aws_ecs_task_definition.db_migrate,
    aws_iam_role_policy.db_migrate_task,
    aws_iam_role_policy.ecs_execution_extra,
    aws_iam_role_policy_attachment.ecs_execution_managed,
    aws_iam_role_policy_attachment.ecs_execution_ecr_public,
    aws_s3_object.db_init_sql,
  ]

  triggers = {
    sql_etag = aws_s3_object.db_init_sql.etag
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      set -euo pipefail
      TASK_ARN=$(aws ecs run-task \
        --region '${var.aws_region}' \
        --cluster '${aws_ecs_cluster.main.name}' \
        --launch-type FARGATE \
        --task-definition '${aws_ecs_task_definition.db_migrate.family}' \
        --network-configuration "awsvpcConfiguration={subnets=[${join(",", aws_subnet.private_app[*].id)}],securityGroups=[${aws_security_group.db_migrate.id}],assignPublicIp=DISABLED}" \
        --query 'tasks[0].taskArn' --output text)
      aws ecs wait tasks-stopped --region '${var.aws_region}' --cluster '${aws_ecs_cluster.main.name}' --tasks "$TASK_ARN"
      EXIT=$(aws ecs describe-tasks --region '${var.aws_region}' --cluster '${aws_ecs_cluster.main.name}' --tasks "$TASK_ARN" \
        --query 'tasks[0].containers[0].exitCode' --output text)
      if [ "$EXIT" != "0" ]; then
        echo "db_migrate task failed exit=$EXIT task=$TASK_ARN" >&2
        exit 1
      fi
    EOT
  }
}
