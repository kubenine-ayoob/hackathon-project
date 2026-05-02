data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.root}/../lambda/handler.py"
  output_path = "${path.module}/build/lambda_process.zip"
}

resource "aws_iam_role" "lambda" {
  name = "${var.name_prefix}-lambda-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "lambda" {
  name = "${var.name_prefix}-lambda-policy"
  role = aws_iam_role.lambda.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = [
          "${aws_cloudwatch_log_group.lambda_process.arn}:*"
        ]
      },
      {
        Effect   = "Allow"
        Action   = ["ssm:GetParameter"]
        Resource = [aws_ssm_parameter.main_backend_url.arn]
      }
    ]
  })
}

resource "aws_lambda_function" "process" {
  function_name    = "${var.name_prefix}-s3-process"
  role               = aws_iam_role.lambda.arn
  filename           = data.archive_file.lambda_zip.output_path
  source_code_hash   = data.archive_file.lambda_zip.output_base64sha256
  handler            = "handler.handler"
  runtime            = "python3.11"
  timeout            = 60
  memory_size        = 256

  logging_config {
    log_format = "Text"
    log_group  = aws_cloudwatch_log_group.lambda_process.name
  }

  tags = { Name = "${var.name_prefix}-lambda-s3-process" }
}

resource "aws_lambda_permission" "s3" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.process.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.uploads.arn
}

resource "aws_s3_bucket_notification" "uploads" {
  bucket = aws_s3_bucket.uploads.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.process.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.s3]
}