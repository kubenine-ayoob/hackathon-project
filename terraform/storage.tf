
locals {
  bucket_prefix = "${var.name_prefix}-${data.aws_caller_identity.current.account_id}"
}


module "s3_uploads" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.2"

  bucket        = "${local.bucket_prefix}-uploads"
  force_destroy = true

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  versioning = {
    enabled = true
  }

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm     = "aws:kms"
        kms_master_key_id = module.kms.key_arn
      }
      bucket_key_enabled = true
    }
  }

  lifecycle_rule = [{
    id      = "expire-noncurrent"
    enabled = true
    noncurrent_version_expiration = {
      noncurrent_days = 30
    }
    abort_incomplete_multipart_upload_days = 7
  }]
}


module "s3_db_init" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.2"

  bucket        = "${local.bucket_prefix}-db-init"
  force_destroy = true

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  versioning = {
    enabled = true
  }

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm     = "aws:kms"
        kms_master_key_id = module.kms.key_arn
      }
      bucket_key_enabled = true
    }
  }
}

resource "aws_s3_object" "db_init_sql" {
  bucket = module.s3_db_init.s3_bucket_id
  key    = "init.sql"
  source = "${path.module}/../db/init.sql"
  etag   = filemd5("${path.module}/../db/init.sql")
}


module "s3_alb_logs" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.2"

  bucket        = "${local.bucket_prefix}-alb-logs"
  force_destroy = true

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true


  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  attach_policy = true
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowELBPutLogs"
      Effect    = "Allow"
      Principal = { AWS = data.aws_elb_service_account.current.arn }
      Action    = "s3:PutObject"
      Resource  = "arn:aws:s3:::${local.bucket_prefix}-alb-logs/*"
    }]
  })

  lifecycle_rule = [{
    id      = "expire-old-logs"
    enabled = true
    expiration = {
      days = 30
    }
  }]
}


module "ecr" {
  source  = "terraform-aws-modules/ecr/aws"
  version = "~> 2.3"

  for_each = toset(local.service_keys)

  repository_name                 = "${var.name_prefix}-${each.key}"
  repository_image_tag_mutability = "MUTABLE"
  repository_force_delete         = true
  repository_image_scan_on_push   = true

  repository_encryption_type = "KMS"
  repository_kms_key         = module.kms.key_arn


  create_lifecycle_policy = true
  repository_lifecycle_policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 20 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 20
      }
      action = { type = "expire" }
    }]
  })
}
