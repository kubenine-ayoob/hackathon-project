resource "aws_s3_bucket" "uploads" {
  bucket = "${var.name_prefix}-uploads"

  tags = { Name = "${var.name_prefix}-uploads-bucket" }
}

resource "aws_s3_bucket_public_access_block" "uploads" {
  bucket                  = aws_s3_bucket.uploads.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "uploads" {
  bucket = aws_s3_bucket.uploads.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.main.arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket" "db_init" {
  bucket = "${var.name_prefix}-db-init"

  tags = { Name = "${var.name_prefix}-db-init-bucket" }
}

resource "aws_s3_bucket_public_access_block" "db_init" {
  bucket                  = aws_s3_bucket.db_init.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_object" "db_init_sql" {
  bucket = aws_s3_bucket.db_init.id
  key    = "init.sql"
  source = "${path.root}/../db/init.sql"
  etag   = filemd5("${path.root}/../db/init.sql")
}