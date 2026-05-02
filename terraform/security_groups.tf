resource "aws_security_group" "alb_public" {
  name        = "${var.name_prefix}-alb-public-sg"
  description = "Public ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.name_prefix}-alb-public-sg" }
}

resource "aws_security_group" "alb_internal" {
  name        = "${var.name_prefix}-alb-internal-sg"
  description = "Internal ALB for extractor/parser"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "HTTP from ECS tasks"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_tasks.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.name_prefix}-alb-internal-sg" }
}

resource "aws_security_group" "ecs_tasks" {
  name        = "${var.name_prefix}-ecs-tasks-sg"
  description = "All Fargate tasks"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "main-backend from public ALB"
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_public.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.name_prefix}-ecs-tasks-sg" }
}

resource "aws_security_group_rule" "ecs_tasks_from_internal_alb_extract" {
  type                     = "ingress"
  security_group_id        = aws_security_group.ecs_tasks.id
  from_port                = 8001
  to_port                  = 8001
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb_internal.id
}

resource "aws_security_group_rule" "ecs_tasks_from_internal_alb_parse" {
  type                     = "ingress"
  security_group_id        = aws_security_group.ecs_tasks.id
  from_port                = 8002
  to_port                  = 8002
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb_internal.id
}

resource "aws_security_group" "rds" {
  name        = "${var.name_prefix}-rds-sg"
  description = "PostgreSQL"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Postgres from ECS"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_tasks.id, aws_security_group.db_migrate.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.name_prefix}-rds-sg" }
}

resource "aws_security_group" "db_migrate" {
  name        = "${var.name_prefix}-db-migrate-sg"
  description = "One-shot DB init task"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.name_prefix}-db-migrate-sg" }
}