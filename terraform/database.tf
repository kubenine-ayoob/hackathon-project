
resource "random_password" "db" {
  length  = 24
  special = false
}

module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 6.10"

  identifier = "${var.name_prefix}-pg15"

  engine               = "postgres"
  engine_version       = "15"
  family               = "postgres15"
  major_engine_version = "15"
  instance_class       = var.db_instance_class

  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true
  kms_key_id            = module.kms.key_arn

  db_name                     = var.db_name
  username                    = var.db_user
  manage_master_user_password = false
  password                    = random_password.db.result

  multi_az                = var.db_multi_az
  publicly_accessible     = false
  skip_final_snapshot     = var.db_skip_final_snapshot
  backup_retention_period = var.db_backup_retention_days
  deletion_protection     = var.db_deletion_protection

  performance_insights_enabled    = true
  performance_insights_kms_key_id = module.kms.key_arn

  iam_database_authentication_enabled = true

  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = module.vpc.database_subnet_group_name
  create_db_subnet_group = false

  create_db_parameter_group = false
  parameter_group_name      = "default.postgres15"

  create_monitoring_role      = false
  create_cloudwatch_log_group = false
}


module "db_migration" {
  source = "./modules/db-migration"

  name_prefix = var.name_prefix
  aws_region  = var.aws_region

  cluster_name = module.ecs_cluster.name
  cluster_arn  = module.ecs_cluster.arn

  subnet_ids        = module.vpc.private_subnets
  security_group_id = aws_security_group.db_migrate.id

  init_sql_bucket      = module.s3_db_init.s3_bucket_id
  init_sql_object_etag = aws_s3_object.db_init_sql.etag
  init_sql_path        = "${path.module}/../db/init.sql"

  db_host                = module.rds.db_instance_address
  db_name                = var.db_name
  db_user                = var.db_user
  db_password_secret_arn = aws_ssm_parameter.db_password.arn
  kms_key_arn            = module.kms.key_arn

  depends_on = [module.rds, aws_s3_object.db_init_sql]
}
