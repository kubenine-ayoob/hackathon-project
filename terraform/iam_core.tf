data "aws_iam_policy_document" "ecs_task_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_execution" {
  name               = "${var.name_prefix}-ecs-exec"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume.json
  tags               = { Name = "${var.name_prefix}-ecs-exec" }
}

resource "aws_iam_role_policy_attachment" "ecs_execution_managed" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Fargate can pull images from public.ecr.aws (db_migrate + any public images).
resource "aws_iam_role_policy_attachment" "ecs_execution_ecr_public" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonElasticContainerRegistryPublicReadOnly"
}

data "aws_iam_policy_document" "ecs_execution_extra" {
  statement {
    sid = "EcrPull"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage"
    ]
    resources = ["*"]
  }

  statement {
    sid = "SsmReadForSecrets"
    actions = [
      "ssm:GetParameters",
      "ssm:GetParameter",
      "ssm:GetParametersByPath"
    ]
    resources = [
      aws_ssm_parameter.db_host.arn,
      aws_ssm_parameter.db_name.arn,
      aws_ssm_parameter.db_user.arn,
      aws_ssm_parameter.db_password.arn,
      aws_ssm_parameter.s3_bucket.arn,
      aws_ssm_parameter.extractor_url.arn,
      aws_ssm_parameter.parser_url.arn,
    ]
  }

  statement {
    sid = "KmsForSsmAndEcr"
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey"
    ]
    resources = [
      aws_kms_key.main.arn
    ]
  }

  statement {
    sid = "Logs"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "${aws_cloudwatch_log_group.main_backend.arn}:*",
      "${aws_cloudwatch_log_group.extractor.arn}:*",
      "${aws_cloudwatch_log_group.parser.arn}:*",
      "${aws_cloudwatch_log_group.db_migrate.arn}:*"
    ]
  }
}

resource "aws_iam_role_policy" "ecs_execution_extra" {
  name   = "${var.name_prefix}-ecs-exec-extra"
  role   = aws_iam_role.ecs_execution.id
  policy = data.aws_iam_policy_document.ecs_execution_extra.json
}

resource "aws_iam_role" "main_backend_task" {
  name               = "${var.name_prefix}-main-backend-task"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume.json
  tags               = { Name = "${var.name_prefix}-main-backend-task" }
}

data "aws_iam_policy_document" "main_backend_task" {
  statement {
    sid = "S3UploadsWrite"
    actions = [
      "s3:PutObject",
      "s3:AbortMultipartUpload",
      "s3:ListBucketMultipartUploads"
    ]
    resources = [
      aws_s3_bucket.uploads.arn,
      "${aws_s3_bucket.uploads.arn}/*"
    ]
  }

  statement {
    sid = "KmsForS3"
    actions = [
      "kms:Encrypt",
      "kms:GenerateDataKey",
      "kms:Decrypt",
      "kms:DescribeKey"
    ]
    resources = [aws_kms_key.main.arn]
  }
}

resource "aws_iam_role_policy" "main_backend_task" {
  name   = "${var.name_prefix}-main-backend-task"
  role   = aws_iam_role.main_backend_task.id
  policy = data.aws_iam_policy_document.main_backend_task.json
}

resource "aws_iam_role" "extractor_task" {
  name               = "${var.name_prefix}-extractor-task"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume.json
  tags               = { Name = "${var.name_prefix}-extractor-task" }
}

data "aws_iam_policy_document" "extractor_task" {
  statement {
    sid = "S3UploadsRead"
    actions = [
      "s3:GetObject",
      "s3:ListBucket"
    ]
    resources = [
      aws_s3_bucket.uploads.arn,
      "${aws_s3_bucket.uploads.arn}/*"
    ]
  }

  statement {
    sid = "KmsForS3"
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey"
    ]
    resources = [aws_kms_key.main.arn]
  }
}

resource "aws_iam_role_policy" "extractor_task" {
  name   = "${var.name_prefix}-extractor-task"
  role   = aws_iam_role.extractor_task.id
  policy = data.aws_iam_policy_document.extractor_task.json
}

resource "aws_iam_role" "parser_task" {
  name               = "${var.name_prefix}-parser-task"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume.json
  tags               = { Name = "${var.name_prefix}-parser-task" }
}

resource "aws_iam_role_policy" "parser_task" {
  name = "${var.name_prefix}-parser-task"
  role = aws_iam_role.parser_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid      = "DenyAllOptionalExplicit"
      Effect   = "Allow"
      Action   = ["sts:GetCallerIdentity"]
      Resource = "*"
    }]
  })
}

resource "aws_iam_role" "db_migrate_task" {
  name               = "${var.name_prefix}-db-migrate-task"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume.json
  tags               = { Name = "${var.name_prefix}-db-migrate-task" }
}

data "aws_iam_policy_document" "db_migrate_task" {
  statement {
    sid = "S3ReadInit"
    actions = [
      "s3:GetObject"
    ]
    resources = ["${aws_s3_bucket.db_init.arn}/*"]
  }
}

resource "aws_iam_role_policy" "db_migrate_task" {
  name   = "${var.name_prefix}-db-migrate-task"
  role   = aws_iam_role.db_migrate_task.id
  policy = data.aws_iam_policy_document.db_migrate_task.json
}

data "aws_iam_policy_document" "github_oidc_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_repository}:ref:refs/heads/main"]
    }
  }
}

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

resource "aws_iam_role" "github_deploy" {
  name               = "${var.name_prefix}-github-deploy"
  assume_role_policy = data.aws_iam_policy_document.github_oidc_trust.json
  tags               = { Name = "${var.name_prefix}-github-deploy" }
}

data "aws_iam_policy_document" "github_deploy" {
  statement {
    sid    = "TerraformState"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    resources = [
      "arn:aws:s3:::REPLACE_ME_TFSTATE_BUCKET",
      "arn:aws:s3:::REPLACE_ME_TFSTATE_BUCKET/*"
    ]
  }

  statement {
    sid    = "TerraformLock"
    effect = "Allow"
    actions = [
      "dynamodb:PutItem",
      "dynamodb:GetItem",
      "dynamodb:DeleteItem",
      "dynamodb:DescribeTable"
    ]
    resources = ["arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/REPLACE_ME_TFLOCK_TABLE"]
  }

  statement {
    sid    = "TerraformApplyWide"
    effect = "Allow"
    actions = [
      "*"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "github_deploy" {
  name   = "${var.name_prefix}-github-deploy"
  role   = aws_iam_role.github_deploy.id
  policy = data.aws_iam_policy_document.github_deploy.json
}