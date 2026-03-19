################################################################################
# CloudTrail — APRA CPS 234 / CPG 234 Audit Logging
################################################################################

resource "aws_cloudtrail" "this" {
  name                          = "${local.name_prefix}-trail"
  s3_bucket_name                = var.cloudtrail_bucket_name
  is_multi_region_trail         = true
  include_global_service_events = true
  enable_log_file_validation    = true
  kms_key_id                    = var.cloudtrail_kms_key_arn

  cloud_watch_logs_group_arn = var.cloudtrail_log_group_arn != "" ? "${var.cloudtrail_log_group_arn}:*" : null
  cloud_watch_logs_role_arn  = var.cloudtrail_log_group_arn != "" ? aws_iam_role.cloudtrail_cloudwatch[0].arn : null

  event_selector {
    read_write_type           = "All"
    include_management_events = true
  }

  tags = merge(var.tags, {
    Name = "${local.name_prefix}-trail"
  })
}

# ---------------------------------------------------------------------------
# IAM role for CloudTrail -> CloudWatch Logs delivery
# ---------------------------------------------------------------------------
resource "aws_iam_role" "cloudtrail_cloudwatch" {
  count = var.cloudtrail_log_group_arn != "" ? 1 : 0

  name = "${local.name_prefix}-cloudtrail-cw-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "cloudtrail_cloudwatch" {
  count = var.cloudtrail_log_group_arn != "" ? 1 : 0

  name = "${local.name_prefix}-cloudtrail-cw-policy"
  role = aws_iam_role.cloudtrail_cloudwatch[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${var.cloudtrail_log_group_arn}:*"
      }
    ]
  })
}
