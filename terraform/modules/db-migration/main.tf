terraform {
  required_version = ">= 1.5"
  required_providers {
    aws  = { source = "hashicorp/aws", version = "~> 5.0" }
    null = { source = "hashicorp/null", version = "~> 3.2" }
  }
}


resource "aws_cloudwatch_log_group" "this" {
  name              = "/ecs/${var.name_prefix}-db-migrate"
  retention_in_days = 3
}

data "aws_iam_policy_document" "assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "exec" {
  name               = "${var.name_prefix}-db-migrate-exec"
  assume_role_policy = data.aws_iam_policy_document.assume.json
}

resource "aws_iam_role_policy_attachment" "exec_managed" {
  role       = aws_iam_role.exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "exec_logs_and_secrets" {
  name = "${var.name_prefix}-db-migrate-exec-extras"
  role = aws_iam_role.exec.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "Logs"
        Effect   = "Allow"
        Action   = ["logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = ["${aws_cloudwatch_log_group.this.arn}:*"]
      },
      {
        Sid      = "ReadDbPasswordSecret"
        Effect   = "Allow"
        Action   = ["ssm:GetParameters"]
        Resource = [var.db_password_secret_arn]
      },
      {
        Sid      = "DecryptForSsm"
        Effect   = "Allow"
        Action   = ["kms:Decrypt", "kms:DescribeKey"]
        Resource = [var.kms_key_arn]
      },
    ]
  })
}

resource "aws_iam_role" "task" {
  name               = "${var.name_prefix}-db-migrate-task"
  assume_role_policy = data.aws_iam_policy_document.assume.json
}

resource "aws_iam_role_policy" "task_s3_read" {
  name = "${var.name_prefix}-db-migrate-task"
  role = aws_iam_role.task.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid      = "S3ReadInit"
      Effect   = "Allow"
      Action   = ["s3:GetObject"]
      Resource = ["arn:aws:s3:::${var.init_sql_bucket}/*"]
    }]
  })
}

resource "aws_ecs_task_definition" "this" {
  family                   = "${var.name_prefix}-db-migrate"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.exec.arn
  task_role_arn            = aws_iam_role.task.arn

  container_definitions = jsonencode([{
    name      = "db-migrate"
    image     = "public.ecr.aws/docker/library/postgres:15"
    essential = true
    command = [
      "bash", "-lc",
      join(" && ", [
        "apt-get update -qq",
        "DEBIAN_FRONTEND=noninteractive apt-get install -y -qq awscli",
        "aws s3 cp 's3://${var.init_sql_bucket}/init.sql' /tmp/init.sql",
        # PGPASSWORD is read from the env var injected via `secrets` below.
        # No Terraform interpolation of the password — keeps it out of state.
        "PGPASSWORD=\"$DB_PASSWORD\" psql -h '${var.db_host}' -U '${var.db_user}' -d '${var.db_name}' -f /tmp/init.sql",
        "echo db_init_ok",
      ])
    ]
    environment = [
      { name = "DB_HOST", value = var.db_host },
      { name = "DB_NAME", value = var.db_name },
      { name = "DB_USER", value = var.db_user },
    ]
    secrets = [
      { name = "DB_PASSWORD", valueFrom = var.db_password_secret_arn },
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.this.name
        awslogs-region        = var.aws_region
        awslogs-stream-prefix = "ecs"
      }
    }
  }])
}

resource "null_resource" "run" {
  triggers = {
    sql_etag = var.init_sql_object_etag
    task_def = aws_ecs_task_definition.this.arn
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      set -euo pipefail

      # Retry run-task to absorb IAM eventual-consistency: the task role and
      # execution role were created seconds ago and ECS may not see them yet.
      TASK_ARN=""
      for attempt in 1 2 3 4 5 6; do
        if TASK_ARN=$(aws ecs run-task \
            --region '${var.aws_region}' \
            --cluster '${var.cluster_name}' \
            --launch-type FARGATE \
            --task-definition '${aws_ecs_task_definition.this.family}' \
            --network-configuration "awsvpcConfiguration={subnets=[${join(",", var.subnet_ids)}],securityGroups=[${var.security_group_id}],assignPublicIp=DISABLED}" \
            --query 'tasks[0].taskArn' --output text 2>&1) && [ -n "$TASK_ARN" ] && [ "$TASK_ARN" != "None" ]; then
          echo "run-task succeeded on attempt $attempt: $TASK_ARN"
          break
        fi
        echo "run-task attempt $attempt failed: $TASK_ARN" >&2
        TASK_ARN=""
        sleep 15
      done

      if [ -z "$TASK_ARN" ]; then
        echo "run-task failed after 6 attempts" >&2
        exit 1
      fi

      aws ecs wait tasks-stopped --region '${var.aws_region}' --cluster '${var.cluster_name}' --tasks "$TASK_ARN"
      EXIT=$(aws ecs describe-tasks --region '${var.aws_region}' --cluster '${var.cluster_name}' --tasks "$TASK_ARN" \
        --query 'tasks[0].containers[0].exitCode' --output text)
      if [ "$EXIT" != "0" ]; then
        echo "db_migrate task failed exit=$EXIT task=$TASK_ARN" >&2
        echo "Check CloudWatch logs: ${aws_cloudwatch_log_group.this.name}" >&2
        exit 1
      fi
      echo "db_migrate task succeeded"
    EOT
  }

  depends_on = [
    aws_iam_role.task,
    aws_iam_role.exec,
    aws_iam_role_policy.task_s3_read,
    aws_iam_role_policy.exec_logs_and_secrets,
    aws_iam_role_policy_attachment.exec_managed,
    aws_ecs_task_definition.this,
  ]
}
