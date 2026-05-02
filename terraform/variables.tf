variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "owner_name" {
  type        = string
  description = "Short name for tags, e.g. alice"
}

variable "name_prefix" {
  type        = string
  description = "Must match TASK naming, e.g. hackthon-k9-intern-alice"
}

variable "github_repository" {
  type        = string
  description = "For OIDC trust policy, format: ORG/REPO"
}

variable "db_name" {
  type    = string
  default = "stacknine"
}

variable "db_user" {
  type    = string
  default = "postgres"
}

variable "main_backend_desired_count" {
  type    = number
  default = 1
}

variable "sidecar_desired_count" {
  type    = number
  default = 1
}