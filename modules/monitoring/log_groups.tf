################################################################################
# CloudWatch Log Groups — Amazon Connect
################################################################################

resource "aws_cloudwatch_log_group" "connect" {
  name              = "/aws/connect/${var.project_name}-${var.environment}"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.logs_kms_key_arn

  tags = var.tags
}
