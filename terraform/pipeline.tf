
module "github_oidc_provider" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-github-oidc-provider"
  version = "~> 5.48"

  create = var.create_github_oidc_provider
}

module "github_deploy_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-github-oidc-role"
  version = "~> 5.48"

  name     = "${var.name_prefix}-github-deploy"
  subjects = ["${var.github_repository}:ref:refs/heads/${var.github_branch}"]

  policies = {
    state = aws_iam_policy.github_state.arn
    apply = aws_iam_policy.github_apply.arn
  }
}


resource "aws_iam_policy" "github_state" {
  name = "${var.name_prefix}-github-state"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "TerraformStateBucket"
        Effect = "Allow"
        Action = ["s3:ListBucket", "s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource = [
          "arn:aws:s3:::${var.tfstate_bucket}",
          "arn:aws:s3:::${var.tfstate_bucket}/*",
        ]
      },
      {
        Sid      = "TerraformStateLock"
        Effect   = "Allow"
        Action   = ["dynamodb:PutItem", "dynamodb:GetItem", "dynamodb:DeleteItem", "dynamodb:DescribeTable"]
        Resource = ["arn:aws:dynamodb:${var.aws_region}:${local.account_id}:table/${var.tflock_table}"]
      },
    ]
  })
}


resource "aws_iam_policy" "github_apply" {
  name = "${var.name_prefix}-github-apply"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Networking"
        Effect = "Allow"
        Action = [
          "ec2:*",
          "elasticloadbalancing:*",
        ]
        Resource = "*"
      },
      {
        Sid    = "ContainerCompute"
        Effect = "Allow"
        Action = [
          "ecs:*",
          "ecr:*",
          "application-autoscaling:*",
        ]
        Resource = "*"
      },
      {
        Sid    = "ServerlessCompute"
        Effect = "Allow"
        Action = [
          "lambda:*",
          "events:*",
        ]
        Resource = "*"
      },
      {
        Sid      = "DataStores"
        Effect   = "Allow"
        Action   = ["rds:*", "s3:*"]
        Resource = "*"
      },
      {
        Sid    = "SecretsAndCrypto"
        Effect = "Allow"
        Action = [
          "ssm:*",
          "secretsmanager:*",
          "kms:*",
        ]
        Resource = "*"
      },
      {
        Sid    = "Identity"
        Effect = "Allow"
        Action = [
          "iam:GetRole",
          "iam:GetRolePolicy",
          "iam:GetPolicy",
          "iam:GetPolicyVersion",
          "iam:ListRoles",
          "iam:ListRolePolicies",
          "iam:ListAttachedRolePolicies",
          "iam:ListPolicies",
          "iam:ListPolicyVersions",
          "iam:ListInstanceProfilesForRole",
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:UpdateRole",
          "iam:UpdateAssumeRolePolicy",
          "iam:CreatePolicy",
          "iam:DeletePolicy",
          "iam:CreatePolicyVersion",
          "iam:DeletePolicyVersion",
          "iam:PutRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:PassRole",
          "iam:TagRole",
          "iam:UntagRole",
          "iam:TagPolicy",
          "iam:UntagPolicy",
          "iam:CreateOpenIDConnectProvider",
          "iam:DeleteOpenIDConnectProvider",
          "iam:GetOpenIDConnectProvider",
          "iam:UpdateOpenIDConnectProviderThumbprint",
          "iam:AddClientIDToOpenIDConnectProvider",
          "iam:RemoveClientIDFromOpenIDConnectProvider",
          "iam:TagOpenIDConnectProvider",
        ]
        Resource = "*"
      },
      {
        Sid    = "Observability"
        Effect = "Allow"
        Action = [
          "cloudwatch:*",
          "logs:*",
          "sns:*",
        ]
        Resource = "*"
      },
    ]
  })
}
