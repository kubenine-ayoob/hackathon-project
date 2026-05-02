locals {
  ecr_registry = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com"
}

resource "aws_ecs_task_definition" "main_backend" {
  family                   = "${var.name_prefix}-main-backend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.main_backend_task.arn

  container_definitions = jsonencode([{
    name  = "main-backend"
    image = "${local.ecr_registry}/${aws_ecr_repository.app["main-backend"].name}:latest"
    portMappings = [{
      containerPort = 8000
      protocol      = "tcp"
    }]
    environment = [
      { name = "ENV", value = "production" },
      { name = "DB_PORT", value = "5432" },
      { name = "UPLOAD_DIR", value = "/tmp" }
    ]
    secrets = [
      { name = "DB_HOST", valueFrom = aws_ssm_parameter.db_host.arn },
      { name = "DB_NAME", valueFrom = aws_ssm_parameter.db_name.arn },
      { name = "DB_USER", valueFrom = aws_ssm_parameter.db_user.arn },
      { name = "DB_PASSWORD", valueFrom = aws_ssm_parameter.db_password.arn },
      { name = "S3_BUCKET", valueFrom = aws_ssm_parameter.s3_bucket.arn },
      { name = "EXTRACTOR_URL", valueFrom = aws_ssm_parameter.extractor_url.arn },
      { name = "PARSER_URL", valueFrom = aws_ssm_parameter.parser_url.arn }
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.main_backend.name
        awslogs-region        = var.aws_region
        awslogs-stream-prefix = "ecs"
      }
    }
  }])
}

resource "aws_ecs_task_definition" "extractor" {
  family                   = "${var.name_prefix}-extractor"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.extractor_task.arn

  container_definitions = jsonencode([{
    name  = "extractor"
    image = "${local.ecr_registry}/${aws_ecr_repository.app["extractor"].name}:latest"
    portMappings = [{
      containerPort = 8001
      protocol      = "tcp"
    }]
    environment = [
      { name = "DB_PORT", value = "5432" },
      { name = "UPLOAD_DIR", value = "/tmp" }
    ]
    secrets = [
      { name = "DB_HOST", valueFrom = aws_ssm_parameter.db_host.arn },
      { name = "DB_NAME", valueFrom = aws_ssm_parameter.db_name.arn },
      { name = "DB_USER", valueFrom = aws_ssm_parameter.db_user.arn },
      { name = "DB_PASSWORD", valueFrom = aws_ssm_parameter.db_password.arn },
      { name = "S3_BUCKET", valueFrom = aws_ssm_parameter.s3_bucket.arn }
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.extractor.name
        awslogs-region        = var.aws_region
        awslogs-stream-prefix = "ecs"
      }
    }
  }])
}

resource "aws_ecs_task_definition" "parser" {
  family                   = "${var.name_prefix}-parser"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.parser_task.arn

  container_definitions = jsonencode([{
    name  = "parser"
    image = "${local.ecr_registry}/${aws_ecr_repository.app["parser"].name}:latest"
    portMappings = [{
      containerPort = 8002
      protocol      = "tcp"
    }]
    environment = [
      { name = "DB_PORT", value = "5432" }
    ]
    secrets = [
      { name = "DB_HOST", valueFrom = aws_ssm_parameter.db_host.arn },
      { name = "DB_NAME", valueFrom = aws_ssm_parameter.db_name.arn },
      { name = "DB_USER", valueFrom = aws_ssm_parameter.db_user.arn },
      { name = "DB_PASSWORD", valueFrom = aws_ssm_parameter.db_password.arn }
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.parser.name
        awslogs-region        = var.aws_region
        awslogs-stream-prefix = "ecs"
      }
    }
  }])
}