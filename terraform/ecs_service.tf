resource "aws_ecs_service" "main_backend" {
  name            = "${var.name_prefix}-main-backend-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.main_backend.arn
  desired_count   = var.main_backend_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private_app[*].id
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.main_backend.arn
    container_name   = "main-backend"
    container_port   = 8000
  }

  depends_on = [aws_lb_listener.public_http, null_resource.db_migrate_run]

  tags = { Name = "${var.name_prefix}-main-backend-service" }
}

resource "aws_ecs_service" "extractor" {
  name             = "${var.name_prefix}-extractor-service"
  cluster          = aws_ecs_cluster.main.id
  task_definition  = aws_ecs_task_definition.extractor.arn
  desired_count    = var.sidecar_desired_count
  launch_type      = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private_app[*].id
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.extractor.arn
    container_name   = "extractor"
    container_port   = 8001
  }

  depends_on = [aws_lb_listener_rule.extract, null_resource.db_migrate_run]

  tags = { Name = "${var.name_prefix}-extractor-service" }
}

resource "aws_ecs_service" "parser" {
  name             = "${var.name_prefix}-parser-service"
  cluster          = aws_ecs_cluster.main.id
  task_definition  = aws_ecs_task_definition.parser.arn
  desired_count    = var.sidecar_desired_count
  launch_type      = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private_app[*].id
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.parser.arn
    container_name   = "parser"
    container_port   = 8002
  }

  depends_on = [aws_lb_listener_rule.parse, null_resource.db_migrate_run]

  tags = { Name = "${var.name_prefix}-parser-service" }
}