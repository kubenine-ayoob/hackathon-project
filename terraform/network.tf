
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.13"

  name = "${var.name_prefix}-vpc"
  cidr = var.vpc_cidr
  azs  = local.azs

  public_subnets   = [for i in range(length(local.azs)) : cidrsubnet(var.vpc_cidr, 4, i)]
  private_subnets  = [for i in range(length(local.azs)) : cidrsubnet(var.vpc_cidr, 4, i + 10)]
  database_subnets = [for i in range(length(local.azs)) : cidrsubnet(var.vpc_cidr, 4, i + 12)]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true

  create_database_subnet_group = true

  enable_flow_log                                 = true
  create_flow_log_cloudwatch_log_group            = true
  create_flow_log_cloudwatch_iam_role             = true
  flow_log_max_aggregation_interval               = 60
  flow_log_cloudwatch_log_group_retention_in_days = 14

  public_subnet_tags   = { Tier = "public" }
  private_subnet_tags  = { Tier = "private-app" }
  database_subnet_tags = { Tier = "private-data" }
}
