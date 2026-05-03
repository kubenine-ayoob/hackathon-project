
module "ecs_cluster" {
  source  = "terraform-aws-modules/ecs/aws//modules/cluster"
  version = "~> 5.11"

  cluster_name = "${var.name_prefix}-cluster"

  cluster_settings = [{
    name  = "containerInsights"
    value = "enabled"
  }]

  create_cloudwatch_log_group = false
}


locals {
  ecs_services = {
    main-backend = {
      cpu                      = 512
      memory                   = 1024
      desired_count            = var.main_backend_desired_count
      container_port           = 8000
      target_group_arn         = module.alb_public.target_groups["main-backend"].arn
      enable_autoscaling       = true
      readonly_root_filesystem = true

      environment = [
        { name = "ENV", value = "production" },
        { name = "DB_PORT", value = "5432" },
        { name = "UPLOAD_DIR", value = "/tmp" },
      ]

      secrets = concat(
        local.db_secret_refs,
        [local.s3_secret_ref],
        local.url_secret_refs,
      )

      task_iam_statements = [
        {
          sid     = "S3UploadsWrite"
          actions = ["s3:PutObject", "s3:AbortMultipartUpload", "s3:ListBucketMultipartUploads"]
          resources = [
            module.s3_uploads.s3_bucket_arn,
            "${module.s3_uploads.s3_bucket_arn}/*",
          ]
        },
        {
          sid       = "KmsForS3"
          actions   = ["kms:Encrypt", "kms:GenerateDataKey", "kms:Decrypt", "kms:DescribeKey"]
          resources = [module.kms.key_arn]
        },
      ]
    }

    extractor = {
      cpu                = 512
      memory             = 1024
      desired_count      = var.sidecar_desired_count
      container_port     = 8001
      target_group_arn   = module.alb_internal.target_groups["extractor"].arn
      enable_autoscaling = false
      # extractor downloads PDFs from S3 to /tmp/ before parsing — needs RW root.
      # TODO: replace with a dedicated tmpfs volume mount for tighter security.
      readonly_root_filesystem = false

      environment = [
        { name = "DB_PORT", value = "5432" },
        { name = "UPLOAD_DIR", value = "/tmp" },
      ]

      secrets = concat(
        local.db_secret_refs,
        [local.s3_secret_ref],
      )

      task_iam_statements = [
        {
          sid     = "S3UploadsRead"
          actions = ["s3:GetObject", "s3:ListBucket"]
          resources = [
            module.s3_uploads.s3_bucket_arn,
            "${module.s3_uploads.s3_bucket_arn}/*",
          ]
        },
        {
          sid       = "KmsForS3"
          actions   = ["kms:Decrypt", "kms:DescribeKey"]
          resources = [module.kms.key_arn]
        },
      ]
    }

    parser = {
      cpu                      = 256
      memory                   = 512
      desired_count            = var.sidecar_desired_count
      container_port           = 8002
      target_group_arn         = module.alb_internal.target_groups["parser"].arn
      enable_autoscaling       = false
      readonly_root_filesystem = true

      environment = [
        { name = "DB_PORT", value = "5432" },
      ]

      secrets = local.db_secret_refs

      task_iam_statements = []
    }
  }

  # Build the full secret-ARN allow-list per service for the execution role.
  ecs_service_exec_secret_arns = {
    for k, v in local.ecs_services : k => [for s in v.secrets : s.valueFrom]
  }
}

module "ecs_services" {
  source = "./modules/ecs-service"

  for_each = local.ecs_services

  name        = "${var.name_prefix}-${each.key}"
  cluster_arn = module.ecs_cluster.arn

  container_name = each.key
  container_port = each.value.container_port
  image          = "${module.ecr[each.key].repository_url}:${var.image_tags[each.key]}"

  cpu           = each.value.cpu
  memory        = each.value.memory
  desired_count = each.value.desired_count

  subnet_ids         = module.vpc.private_subnets
  security_group_ids = [aws_security_group.ecs_tasks.id]
  target_group_arn   = each.value.target_group_arn

  environment           = each.value.environment
  secrets               = each.value.secrets
  task_exec_secret_arns = local.ecs_service_exec_secret_arns[each.key]
  kms_key_arn           = module.kms.key_arn

  tasks_iam_role_statements = each.value.task_iam_statements

  enable_autoscaling       = each.value.enable_autoscaling
  enable_execute_command   = var.enable_ecs_exec
  readonly_root_filesystem = each.value.readonly_root_filesystem

  # Tasks should not start until DB schema is initialized.
  depends_on_resources = [module.db_migration.completion_marker]
}
