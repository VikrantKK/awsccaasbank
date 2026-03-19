###############################################################################
# Data sources
###############################################################################

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

locals {
  account_id  = data.aws_caller_identity.current.account_id
  partition   = data.aws_partition.current.partition
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = merge(var.tags, {
    Module      = "security"
    Environment = var.environment
    Project     = var.project_name
  })
}

###############################################################################
# KMS key policy — shared baseline allowing account-level administration
###############################################################################

data "aws_iam_policy_document" "kms_key_policy" {
  # Allow account root full access (required for key administration)
  statement {
    sid    = "EnableRootAccountAccess"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:${local.partition}:iam::${local.account_id}:root"]
    }

    actions   = ["kms:*"]
    resources = ["*"]
  }

  # Allow key administrators to manage the key
  statement {
    sid    = "AllowKeyAdministration"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:${local.partition}:iam::${local.account_id}:root"]
    }

    actions = [
      "kms:Create*",
      "kms:Describe*",
      "kms:Enable*",
      "kms:List*",
      "kms:Put*",
      "kms:Update*",
      "kms:Revoke*",
      "kms:Disable*",
      "kms:Get*",
      "kms:Delete*",
      "kms:TagResource",
      "kms:UntagResource",
      "kms:ScheduleKeyDeletion",
      "kms:CancelKeyDeletion",
    ]

    resources = ["*"]
  }
}

###############################################################################
# KMS Key — Amazon Connect encryption
###############################################################################

resource "aws_kms_key" "connect_key" {
  description             = "CMK for Amazon Connect instance encryption — ${local.name_prefix}"
  deletion_window_in_days = var.kms_deletion_window_days
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.kms_key_policy.json

  tags = merge(local.common_tags, {
    Name    = "${local.name_prefix}-connect"
    Purpose = "connect-encryption"
  })
}

resource "aws_kms_alias" "connect_key" {
  name          = "alias/westpac-ccaas-${var.environment}-connect"
  target_key_id = aws_kms_key.connect_key.key_id
}

###############################################################################
# KMS Key — S3 storage encryption (recordings, transcripts)
###############################################################################

resource "aws_kms_key" "storage_key" {
  description             = "CMK for S3 bucket encryption (recordings, transcripts) — ${local.name_prefix}"
  deletion_window_in_days = var.kms_deletion_window_days
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.kms_key_policy.json

  tags = merge(local.common_tags, {
    Name    = "${local.name_prefix}-storage"
    Purpose = "s3-encryption"
  })
}

resource "aws_kms_alias" "storage_key" {
  name          = "alias/westpac-ccaas-${var.environment}-storage"
  target_key_id = aws_kms_key.storage_key.key_id
}

###############################################################################
# KMS Key — DynamoDB table encryption
###############################################################################

resource "aws_kms_key" "dynamodb_key" {
  description             = "CMK for DynamoDB table encryption — ${local.name_prefix}"
  deletion_window_in_days = var.kms_deletion_window_days
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.kms_key_policy.json

  tags = merge(local.common_tags, {
    Name    = "${local.name_prefix}-dynamodb"
    Purpose = "dynamodb-encryption"
  })
}

resource "aws_kms_alias" "dynamodb_key" {
  name          = "alias/westpac-ccaas-${var.environment}-dynamodb"
  target_key_id = aws_kms_key.dynamodb_key.key_id
}

###############################################################################
# KMS Key — CloudWatch Logs encryption
###############################################################################

resource "aws_kms_key" "logs_key" {
  description             = "CMK for CloudWatch Logs encryption — ${local.name_prefix}"
  deletion_window_in_days = var.kms_deletion_window_days
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.kms_key_policy.json

  tags = merge(local.common_tags, {
    Name    = "${local.name_prefix}-logs"
    Purpose = "cloudwatch-logs-encryption"
  })
}

resource "aws_kms_alias" "logs_key" {
  name          = "alias/westpac-ccaas-${var.environment}-logs"
  target_key_id = aws_kms_key.logs_key.key_id
}
