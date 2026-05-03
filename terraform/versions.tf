terraform {
  required_version = "~> 1.9"

  required_providers {
    aws     = { source = "hashicorp/aws", version = "~> 5.0" }
    archive = { source = "hashicorp/archive", version = "~> 2.4" }
    random  = { source = "hashicorp/random", version = "~> 3.6" }
    null    = { source = "hashicorp/null", version = "~> 3.2" }
  }


  backend "s3" {
    bucket         = "hackthon-k9-intern-ayoob-tfstate"
    key            = "stacknine/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "hackthon-k9-intern-ayoob-tflock"
    encrypt        = true
  }
}
