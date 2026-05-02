resource "aws_ssm_parameter" "db_host" {
  name  = "/stacknine/db-host"
  type  = "String"
  value = aws_db_instance.postgres.address

  tags = { Name = "${var.name_prefix}-db-host" }
}

resource "aws_ssm_parameter" "db_name" {
  name  = "/stacknine/db-name"
  type  = "String"
  value = var.db_name
  tags  = { Name = "${var.name_prefix}-db-name" }
}

resource "aws_ssm_parameter" "db_user" {
  name  = "/stacknine/db-user"
  type  = "String"
  value = var.db_user
  tags  = { Name = "${var.name_prefix}-db-user" }
}

resource "aws_ssm_parameter" "db_password" {
  name  = "/stacknine/db-password"
  type  = "SecureString"
  value = random_password.db.result
  key_id = aws_kms_key.main.id

  tags = { Name = "${var.name_prefix}-db-password" }
}

resource "aws_ssm_parameter" "s3_bucket" {
  name  = "/stacknine/s3-bucket"
  type  = "String"
  value = aws_s3_bucket.uploads.bucket
  tags  = { Name = "${var.name_prefix}-s3-bucket" }
}

resource "aws_ssm_parameter" "extractor_url" {
  name  = "/stacknine/extractor-url"
  type  = "String"
  value = "http://${aws_lb.internal.dns_name}"
  tags  = { Name = "${var.name_prefix}-extractor-url" }
}

resource "aws_ssm_parameter" "parser_url" {
  name  = "/stacknine/parser-url"
  type  = "String"
  value = "http://${aws_lb.internal.dns_name}"
  tags  = { Name = "${var.name_prefix}-parser-url" }
}

resource "aws_ssm_parameter" "main_backend_url" {
  name  = "/stacknine/main-backend-url"
  type  = "String"
  value = "http://${aws_lb.public.dns_name}"
  tags  = { Name = "${var.name_prefix}-main-backend-url" }

  depends_on = [aws_lb.public]
}