locals {
  services = ["main-backend", "extractor", "parser"]
}

resource "aws_ecr_repository" "app" {
  for_each             = toset(local.services)
  name                 = "${var.name_prefix}-${each.key}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = aws_kms_key.main.arn
  }

  tags = { Name = "${var.name_prefix}-${each.key}-ecr" }
}