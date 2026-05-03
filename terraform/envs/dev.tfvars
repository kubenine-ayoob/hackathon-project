aws_region        = "us-east-1"
environment       = "dev"
owner_name        = "alice"
name_prefix       = "hackthon-k9-intern-alice"
github_repository = "kubenine-ayoob/hackathon-project"
github_branch     = "main"

# Set to false if your AWS account already has the GitHub OIDC provider
# (token.actions.githubusercontent.com). First-time accounts can leave true.
create_github_oidc_provider = true

tfstate_bucket = "hackthon-k9-intern-ayoob-tfstate"
tflock_table   = "hackthon-k9-intern-ayoob-tflock"

# Per-service image tags. CI overrides at apply time:
#   terraform apply -var-file=envs/dev.tfvars -var='image_tags={main-backend="abc123",extractor="abc123",parser="abc123"}'
image_tags = {
  main-backend = "latest"
  extractor    = "latest"
  parser       = "latest"
}

# Empty = no email subscription. Set to ops alias for real environments.
alarm_email = ""

enable_ecs_exec = false
