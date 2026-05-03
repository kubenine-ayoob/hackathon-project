
resource "aws_ssm_parameter" "this" {
  for_each = local.ssm_string_params

  name  = "${local.ssm_prefix}/${each.key}"
  type  = "String"
  value = each.value

  tags = { Name = "${var.name_prefix}-${each.key}" }
}


resource "aws_ssm_parameter" "db_password" {
  name   = "${local.ssm_prefix}/db-password"
  type   = "SecureString"
  value  = random_password.db.result
  key_id = module.kms.key_id

  tags = { Name = "${var.name_prefix}-db-password" }
}


locals {
  ssm_arns = { for k, v in aws_ssm_parameter.this : k => v.arn }

  db_secret_refs = [
    { name = "DB_HOST", valueFrom = local.ssm_arns["db-host"] },
    { name = "DB_NAME", valueFrom = local.ssm_arns["db-name"] },
    { name = "DB_USER", valueFrom = local.ssm_arns["db-user"] },
    { name = "DB_PASSWORD", valueFrom = aws_ssm_parameter.db_password.arn },
  ]

  s3_secret_ref = { name = "S3_BUCKET", valueFrom = local.ssm_arns["s3-bucket"] }

  url_secret_refs = [
    { name = "EXTRACTOR_URL", valueFrom = local.ssm_arns["extractor-url"] },
    { name = "PARSER_URL", valueFrom = local.ssm_arns["parser-url"] },
  ]
}
