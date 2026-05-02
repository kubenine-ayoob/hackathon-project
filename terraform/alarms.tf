resource "aws_sns_topic" "ops" {
  name = "${var.name_prefix}-ops-alerts"
  tags = { Name = "${var.name_prefix}-ops-alerts" }
}

resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "${var.name_prefix}-alb-5xx"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  alarm_actions       = [aws_sns_topic.ops.arn]
  dimensions = {
    LoadBalancer = aws_lb.public.arn_suffix
  }
}


resource "aws_cloudwatch_metric_alarm" "tg_main_unhealthy" {
  alarm_name          = "${var.name_prefix}-tg-mb-unhealthy"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Maximum"
  threshold           = 0
  alarm_actions       = [aws_sns_topic.ops.arn]
  treat_missing_data  = "breaching"
  dimensions = {
    LoadBalancer = aws_lb.public.arn_suffix
    TargetGroup  = aws_lb_target_group.main_backend.arn_suffix
  }
}

resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "${var.name_prefix}-lambda-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 60
  statistic           = "Sum"
  threshold           = 0
  alarm_actions       = [aws_sns_topic.ops.arn]
  dimensions = {
    FunctionName = aws_lambda_function.process.function_name
  }
}