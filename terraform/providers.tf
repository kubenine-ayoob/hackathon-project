provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "StackNine"
      Environment = "hackathon"
      Owner       = var.owner_name
    }
  }
}