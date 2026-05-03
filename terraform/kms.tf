
module "kms" {
  source  = "terraform-aws-modules/kms/aws"
  version = "~> 3.1"

  description             = "${var.name_prefix} CMK"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  aliases = ["${var.name_prefix}-main"]
}
