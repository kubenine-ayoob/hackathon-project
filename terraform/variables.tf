
variable "aws_region" {
  type        = string
  description = "AWS region all resources are deployed to."
  default     = "us-east-1"
}

variable "owner_name" {
  type        = string
  description = "Short name used in tags, e.g. alice."
}

variable "name_prefix" {
  type        = string
  description = "Prefix for every resource name, e.g. hackthon-k9-intern-alice."

  validation {
    condition     = can(regex("^[a-z0-9-]{3,40}$", var.name_prefix))
    error_message = "name_prefix must be 3-40 chars of lowercase alphanumerics or dashes."
  }
}

variable "environment" {
  type        = string
  description = "Logical environment (dev / staging / prod)."
  default     = "dev"
}


variable "github_repository" {
  type        = string
  description = "GitHub repo allowed to assume the deploy role, format ORG/REPO."
}

variable "github_branch" {
  type        = string
  description = "Branch the deploy role trusts (sub claim)."
  default     = "main"
}

variable "create_github_oidc_provider" {
  type        = bool
  description = "Create the token.actions.githubusercontent.com OIDC provider. Set to false if the account already has one (very common)."
  default     = true
}

variable "tfstate_bucket" {
  type        = string
  description = "Terraform state bucket (granted read/write to deploy role)."
}

variable "tflock_table" {
  type        = string
  description = "Terraform lock DynamoDB table (granted to deploy role)."
}


variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC."
  default     = "10.30.0.0/16"
}

variable "az_count" {
  type        = number
  description = "Number of AZs to span."
  default     = 2
}


variable "db_name" {
  type    = string
  default = "stacknine"
}

variable "db_user" {
  type    = string
  default = "postgres"
}

variable "db_instance_class" {
  type    = string
  default = "db.t4g.micro"
}

variable "db_allocated_storage" {
  type    = number
  default = 20
}

variable "db_max_allocated_storage" {
  type    = number
  default = 50
}

variable "db_backup_retention_days" {
  type        = number
  description = "RDS automated backup retention (days). >=7 recommended for prod."
  default     = 1
}

variable "db_deletion_protection" {
  type    = bool
  default = false
}

variable "db_skip_final_snapshot" {
  type    = bool
  default = true
}

variable "db_multi_az" {
  type    = bool
  default = true
}


variable "image_tags" {
  type = map(string)
  default = {
    main-backend = "latest"
    extractor    = "latest"
    parser       = "latest"
  }
  description = "Container image tag per service key."
}

variable "main_backend_desired_count" {
  type    = number
  default = 1
}

variable "sidecar_desired_count" {
  type    = number
  default = 1
}

variable "enable_ecs_exec" {
  type        = bool
  description = "Enable ECS Exec for live container shell (debug only)."
  default     = false
}


variable "alarm_email" {
  type        = string
  description = "Email subscribed to the ops SNS topic. Empty = no subscription."
  default     = ""
}
