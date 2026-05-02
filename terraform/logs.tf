resource "aws_cloudwatch_log_group" "main_backend" {
  name              = "/ecs/${var.name_prefix}-main-backend"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "extractor" {
  name              = "/ecs/${var.name_prefix}-extractor"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "parser" {
  name              = "/ecs/${var.name_prefix}-parser"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "db_migrate" {
  name              = "/ecs/${var.name_prefix}-db-migrate"
  retention_in_days = 3
}

resource "aws_cloudwatch_log_group" "lambda_process" {
  name              = "/aws/lambda/${var.name_prefix}-s3-process"
  retention_in_days = 14
}