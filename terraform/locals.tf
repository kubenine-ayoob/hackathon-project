locals {
  account_id   = data.aws_caller_identity.current.account_id
  azs          = slice(data.aws_availability_zones.available.names, 0, var.az_count)
  ecr_registry = "${local.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com"
  ssm_prefix   = "/${var.name_prefix}"

  common_tags = {
    Project     = "StackNine"
    Environment = var.environment
    Owner       = var.owner_name
    ManagedBy   = "terraform"
    Repository  = var.github_repository
  }

  service_keys = ["main-backend", "extractor", "parser"]


  ssm_string_params = {
    "db-host"          = module.rds.db_instance_address
    "db-name"          = var.db_name
    "db-user"          = var.db_user
    "s3-bucket"        = module.s3_uploads.s3_bucket_id
    "extractor-url"    = "http://${module.alb_internal.dns_name}"
    "parser-url"       = "http://${module.alb_internal.dns_name}"
    "main-backend-url" = "http://${module.alb_public.dns_name}"
  }
}
