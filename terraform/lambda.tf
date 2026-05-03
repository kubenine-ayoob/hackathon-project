
module "lambda_s3_process" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 7.20"

  function_name = "${var.name_prefix}-s3-process"
  description   = "Process S3 uploads"
  handler       = "handler.handler"
  runtime       = "python3.11"
  timeout       = 60
  memory_size   = 256

  source_path = "${path.module}/../lambda/handler.py"

  environment_variables = {
    MAIN_BACKEND_URL           = local.ssm_string_params["main-backend-url"]
    MAIN_BACKEND_URL_SSM_PARAM = aws_ssm_parameter.this["main-backend-url"].name
  }

  attach_policy_statements = true
  policy_statements = {
    ssm_read = {
      effect    = "Allow"
      actions   = ["ssm:GetParameter"]
      resources = [local.ssm_arns["main-backend-url"]]
    }
  }


  cloudwatch_logs_retention_in_days = 14
}

resource "aws_lambda_permission" "s3_invoke" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_s3_process.lambda_function_name
  principal     = "s3.amazonaws.com"
  source_arn    = module.s3_uploads.s3_bucket_arn
}

resource "aws_s3_bucket_notification" "uploads" {
  bucket = module.s3_uploads.s3_bucket_id

  lambda_function {
    lambda_function_arn = module.lambda_s3_process.lambda_function_arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.s3_invoke]
}
