# Terraform — StackNine hackathon stack

AWS infrastructure for the StackNine hackathon project: VPC, ALB(s), ECS Fargate (3 services), RDS PostgreSQL, S3, KMS, SSM, Lambda, CloudWatch alarms, and a GitHub OIDC deploy role.

## Layout

```
terraform/
├── versions.tf          # terraform{} + S3 backend
├── providers.tf         # AWS provider + default_tags
├── variables.tf         # Input variables (no env-specific defaults)
├── locals.tf            # All locals (single source)
├── data.tf              # All data sources
├── outputs.tf           # Stack outputs
├── moved.tf             # State migration blocks (delete after one clean apply)
│
├── network.tf           # VPC + flow logs
├── security.tf          # Security groups
├── kms.tf               # CMK
├── storage.tf           # S3 (uploads, db-init, alb-logs) + ECR
├── database.tf          # RDS + db-migration call
├── loadbalancing.tf     # Public + internal ALBs
├── compute.tf           # ECS cluster + services (via local module)
├── secrets.tf           # SSM parameters
├── functions.tf         # Lambda
├── observability.tf     # SNS + CloudWatch alarms
├── pipeline.tf          # GitHub OIDC + scoped deploy role
│
├── envs/
│   ├── dev.tfvars
│   └── prod.tfvars.example
│
└── modules/
    ├── ecs-service/     # DRYs the 3 ECS services
    └── db-migration/    # One-shot Fargate task to apply init.sql
```

## Quick start

```bash
make init
make plan ENV=dev
make apply ENV=dev
```

## Operations

| Action | Command |
|---|---|
| Apply for an env | `make apply ENV=dev` |
| Show outputs | `make outputs` |
| Format all .tf | `make fmt` |
| CI checks (fmt-check + validate + tflint + tfsec) | `make ci` |
| Destroy | `make destroy ENV=dev` |

## Security defaults baked in

- All S3 buckets: public access blocked, KMS-encrypted (except ALB logs which require AES256), versioning enabled.
- RDS: encrypted at rest with the stack CMK, IAM auth enabled, Performance Insights on.
- KMS key rotation enabled.
- SSM `db-password` is a SecureString; **never** interpolated into ECS commands or local-exec.
- VPC Flow Logs enabled (CloudWatch, 14-day retention).
- ALB access logs enabled to a dedicated bucket with a 30-day expiration policy.
- GitHub deploy role has **service-scoped** permissions (no `*:*`).
- ECS Containers default to `readonly_root_filesystem = true`.

## Rolling out image versions

Override `image_tags` from CI:

```bash
terraform apply -var-file=envs/dev.tfvars \
  -var='image_tags={main-backend="abc123",extractor="abc123",parser="abc123"}'
```

## State migration from the old flat layout

This refactor renames several resources. `moved.tf` contains `moved {}` blocks that map old → new addresses so `terraform plan` shows only metadata moves (no destroys). After one clean apply, you may delete `moved.tf`.

## Known follow-ups

- Add ACM cert + 443 listener on the public ALB (HTTP→HTTPS redirect).
- Consider switching to `manage_master_user_password = true` (RDS-managed Secrets Manager rotation) to remove the password from Terraform state entirely.
- Replace the `null_resource` migration trigger with a CodeBuild project or app-level migrations (Alembic/Flyway).
