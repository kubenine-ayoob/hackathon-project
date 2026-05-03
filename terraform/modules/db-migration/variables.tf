variable "name_prefix" {
  type        = string
  description = "Resource name prefix for all created objects."
}

variable "aws_region" {
  type        = string
  description = "Region the ECS task runs in (used by the local-exec aws CLI)."
}

variable "cluster_name" {
  type        = string
  description = "ECS cluster name (used for run-task)."
}

variable "cluster_arn" {
  type        = string
  description = "ECS cluster ARN (used as a depends-on barrier)."
}

variable "subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs for the one-shot task."
}

variable "security_group_id" {
  type        = string
  description = "SG attached to the migration task."
}

variable "init_sql_bucket" {
  type        = string
  description = "S3 bucket holding init.sql."
}

variable "init_sql_object_etag" {
  type        = string
  description = "ETag of init.sql, used as the re-run trigger."
}

variable "db_host" { type = string }
variable "db_name" { type = string }
variable "db_user" { type = string }

variable "db_password_secret_arn" {
  type        = string
  description = "SSM SecureString ARN containing the DB password (injected as env var, NEVER interpolated)."
}

variable "kms_key_arn" {
  type        = string
  description = "KMS key used by the SecureString (Decrypt permission granted to exec role)."
}

variable "init_sql_path" {
  type        = string
  description = "Local filesystem path to init.sql (for filemd5 + S3 upload)."
}
