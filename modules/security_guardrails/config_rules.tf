################################################################################
# AWS Config Managed Rules — APRA CPG 234 Compliance
################################################################################

# ---------------------------------------------------------------------------
# S3 — Data-at-rest and access controls (CPG 234 §36–39)
# ---------------------------------------------------------------------------
resource "aws_config_config_rule" "s3_bucket_public_read_prohibited" {
  name = "${local.name_prefix}-s3-bucket-public-read-prohibited"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_PUBLIC_READ_PROHIBITED"
  }

  tags = var.tags

  depends_on = [aws_config_configuration_recorder_status.this]
}

resource "aws_config_config_rule" "s3_bucket_public_write_prohibited" {
  name = "${local.name_prefix}-s3-bucket-public-write-prohibited"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_PUBLIC_WRITE_PROHIBITED"
  }

  tags = var.tags

  depends_on = [aws_config_configuration_recorder_status.this]
}

resource "aws_config_config_rule" "s3_bucket_server_side_encryption_enabled" {
  name = "${local.name_prefix}-s3-bucket-sse-enabled"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_SERVER_SIDE_ENCRYPTION_ENABLED"
  }

  tags = var.tags

  depends_on = [aws_config_configuration_recorder_status.this]
}

resource "aws_config_config_rule" "s3_bucket_ssl_requests_only" {
  name = "${local.name_prefix}-s3-bucket-ssl-requests-only"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_SSL_REQUESTS_ONLY"
  }

  tags = var.tags

  depends_on = [aws_config_configuration_recorder_status.this]
}

# ---------------------------------------------------------------------------
# Encryption — EBS and KMS (CPG 234 §36–39)
# ---------------------------------------------------------------------------
resource "aws_config_config_rule" "encrypted_volumes" {
  name = "${local.name_prefix}-encrypted-volumes"

  source {
    owner             = "AWS"
    source_identifier = "ENCRYPTED_VOLUMES"
  }

  tags = var.tags

  depends_on = [aws_config_configuration_recorder_status.this]
}

resource "aws_config_config_rule" "kms_cmk_not_scheduled_for_deletion" {
  name = "${local.name_prefix}-kms-cmk-not-scheduled-for-deletion"

  source {
    owner             = "AWS"
    source_identifier = "KMS_CMK_NOT_SCHEDULED_FOR_DELETION"
  }

  tags = var.tags

  depends_on = [aws_config_configuration_recorder_status.this]
}

# ---------------------------------------------------------------------------
# IAM — Least privilege (CPG 234 §27–30)
# ---------------------------------------------------------------------------
resource "aws_config_config_rule" "iam_no_inline_policy" {
  name = "${local.name_prefix}-iam-no-inline-policy"

  source {
    owner             = "AWS"
    source_identifier = "IAM_NO_INLINE_POLICY"
  }

  tags = var.tags

  depends_on = [aws_config_configuration_recorder_status.this]
}

resource "aws_config_config_rule" "iam_policy_no_statements_with_admin_access" {
  name = "${local.name_prefix}-iam-policy-no-admin-access"

  source {
    owner             = "AWS"
    source_identifier = "IAM_POLICY_NO_STATEMENTS_WITH_ADMIN_ACCESS"
  }

  tags = var.tags

  depends_on = [aws_config_configuration_recorder_status.this]
}

# ---------------------------------------------------------------------------
# CloudTrail — Audit logging (CPG 234 §44–48)
# ---------------------------------------------------------------------------
resource "aws_config_config_rule" "cloudtrail_enabled" {
  name = "${local.name_prefix}-cloudtrail-enabled"

  source {
    owner             = "AWS"
    source_identifier = "CLOUD_TRAIL_ENABLED"
  }

  tags = var.tags

  depends_on = [aws_config_configuration_recorder_status.this]
}

resource "aws_config_config_rule" "cloud_trail_encryption_enabled" {
  name = "${local.name_prefix}-cloud-trail-encryption-enabled"

  source {
    owner             = "AWS"
    source_identifier = "CLOUD_TRAIL_ENCRYPTION_ENABLED"
  }

  tags = var.tags

  depends_on = [aws_config_configuration_recorder_status.this]
}

resource "aws_config_config_rule" "cloud_trail_log_file_validation_enabled" {
  name = "${local.name_prefix}-cloud-trail-log-file-validation"

  source {
    owner             = "AWS"
    source_identifier = "CLOUD_TRAIL_LOG_FILE_VALIDATION_ENABLED"
  }

  tags = var.tags

  depends_on = [aws_config_configuration_recorder_status.this]
}

# ---------------------------------------------------------------------------
# Network — VPC flow logs and SSH (CPG 234 §31–35)
# ---------------------------------------------------------------------------
resource "aws_config_config_rule" "vpc_flow_logs_enabled" {
  name = "${local.name_prefix}-vpc-flow-logs-enabled"

  source {
    owner             = "AWS"
    source_identifier = "VPC_FLOW_LOGS_ENABLED"
  }

  tags = var.tags

  depends_on = [aws_config_configuration_recorder_status.this]
}

resource "aws_config_config_rule" "restricted_ssh" {
  name = "${local.name_prefix}-restricted-ssh"

  source {
    owner             = "AWS"
    source_identifier = "INCOMING_SSH_DISABLED"
  }

  tags = var.tags

  depends_on = [aws_config_configuration_recorder_status.this]
}

# ---------------------------------------------------------------------------
# Database encryption — future-proofing (CPG 234 §36–39)
# ---------------------------------------------------------------------------
resource "aws_config_config_rule" "rds_storage_encrypted" {
  name = "${local.name_prefix}-rds-storage-encrypted"

  source {
    owner             = "AWS"
    source_identifier = "RDS_STORAGE_ENCRYPTED"
  }

  tags = var.tags

  depends_on = [aws_config_configuration_recorder_status.this]
}

resource "aws_config_config_rule" "dynamodb_table_encrypted_kms" {
  name = "${local.name_prefix}-dynamodb-table-encrypted-kms"

  source {
    owner             = "AWS"
    source_identifier = "DYNAMODB_TABLE_ENCRYPTED_KMS"
  }

  tags = var.tags

  depends_on = [aws_config_configuration_recorder_status.this]
}

# ---------------------------------------------------------------------------
# Mandatory tagging — governance and cost allocation (CPG 234 §49–52)
# ---------------------------------------------------------------------------
resource "aws_config_config_rule" "required_tags" {
  name = "${local.name_prefix}-required-tags"

  source {
    owner             = "AWS"
    source_identifier = "REQUIRED_TAGS"
  }

  input_parameters = jsonencode({
    tag1Key = "Project"
    tag2Key = "Environment"
    tag3Key = "Owner"
    tag4Key = "CostCenter"
    tag5Key = "DataClassification"
    tag6Key = "ManagedBy"
  })

  tags = var.tags

  depends_on = [aws_config_configuration_recorder_status.this]
}
