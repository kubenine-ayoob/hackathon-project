
resource "aws_sns_topic" "ops" {
  name = "${var.name_prefix}-ops-alerts"

  kms_master_key_id = "alias/aws/sns"

  tags = { Name = "${var.name_prefix}-ops-alerts" }
}

resource "aws_sns_topic_subscription" "ops_email" {
  count     = var.alarm_email == "" ? 0 : 1
  topic_arn = aws_sns_topic.ops.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}


resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "${var.name_prefix}-alb-5xx"
  alarm_description   = "Public ALB returned >=5 5xx responses in 3 minutes"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  datapoints_to_alarm = 2
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 5
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.ops.arn]
  ok_actions          = [aws_sns_topic.ops.arn]
  dimensions = {
    LoadBalancer = module.alb_public.arn_suffix
  }
}

resource "aws_cloudwatch_metric_alarm" "tg_main_unhealthy" {
  alarm_name          = "${var.name_prefix}-tg-mb-unhealthy"
  alarm_description   = "main-backend has an unhealthy target for 3 of 5 minutes"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 5
  datapoints_to_alarm = 3
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Maximum"
  threshold           = 0
  treat_missing_data  = "breaching"
  alarm_actions       = [aws_sns_topic.ops.arn]
  ok_actions          = [aws_sns_topic.ops.arn]
  dimensions = {
    LoadBalancer = module.alb_public.arn_suffix
    TargetGroup  = module.alb_public.target_groups["main-backend"].arn_suffix
  }
}


resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "${var.name_prefix}-lambda-errors"
  alarm_description   = "Lambda error count > 0 for 2 of 3 minutes"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  datapoints_to_alarm = 2
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 60
  statistic           = "Sum"
  threshold           = 0
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.ops.arn]
  ok_actions          = [aws_sns_topic.ops.arn]
  dimensions = {
    FunctionName = module.lambda_s3_process.lambda_function_name
  }
}

resource "aws_cloudwatch_metric_alarm" "lambda_duration_p99" {
  alarm_name          = "${var.name_prefix}-lambda-duration-p99"
  alarm_description   = "Lambda p99 duration approaching timeout"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 5
  datapoints_to_alarm = 3
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = 60
  extended_statistic  = "p99"
  threshold           = 50000 # ms; timeout is 60s
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.ops.arn]
  dimensions = {
    FunctionName = module.lambda_s3_process.lambda_function_name
  }
}


resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name          = "${var.name_prefix}-rds-cpu-high"
  alarm_description   = "RDS CPU >80% for 5 of 10 minutes"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 10
  datapoints_to_alarm = 5
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.ops.arn]
  dimensions = {
    DBInstanceIdentifier = module.rds.db_instance_identifier
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_storage_low" {
  alarm_name          = "${var.name_prefix}-rds-free-storage-low"
  alarm_description   = "RDS free storage < 5 GiB"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 3
  datapoints_to_alarm = 2
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 5 * 1024 * 1024 * 1024 # 5 GiB in bytes
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.ops.arn]
  dimensions = {
    DBInstanceIdentifier = module.rds.db_instance_identifier
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_connections_high" {
  alarm_name          = "${var.name_prefix}-rds-connections-high"
  alarm_description   = "RDS database connections high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 5
  datapoints_to_alarm = 3
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.ops.arn]
  dimensions = {
    DBInstanceIdentifier = module.rds.db_instance_identifier
  }
}


resource "aws_cloudwatch_metric_alarm" "ecs_cpu" {
  for_each = local.ecs_services

  alarm_name          = "${var.name_prefix}-${each.key}-cpu-high"
  alarm_description   = "ECS service ${each.key} sustained CPU > 85%"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 10
  datapoints_to_alarm = 5
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 85
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.ops.arn]
  dimensions = {
    ClusterName = module.ecs_cluster.name
    ServiceName = "${var.name_prefix}-${each.key}"
  }
  depends_on = [module.ecs_services]
}

resource "aws_cloudwatch_metric_alarm" "ecs_memory" {
  for_each = local.ecs_services

  alarm_name          = "${var.name_prefix}-${each.key}-mem-high"
  alarm_description   = "ECS service ${each.key} sustained memory > 85%"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 10
  datapoints_to_alarm = 5
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 85
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.ops.arn]
  dimensions = {
    ClusterName = module.ecs_cluster.name
    ServiceName = "${var.name_prefix}-${each.key}"
  }
  depends_on = [module.ecs_services]
}
