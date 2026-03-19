################################################################################
# SNS Topics — Alert Routing
################################################################################

# ── Warning Topic ─────────────────────────────────────────────────────────────

resource "aws_sns_topic" "warning" {
  name              = "${var.project_name}-${var.environment}-ccaas-warning"
  kms_master_key_id = var.logs_kms_key_arn

  tags = var.tags
}

# ── Critical Topic ────────────────────────────────────────────────────────────

resource "aws_sns_topic" "critical" {
  name              = "${var.project_name}-${var.environment}-ccaas-critical"
  kms_master_key_id = var.logs_kms_key_arn

  tags = var.tags
}

# ── Email Subscriptions ──────────────────────────────────────────────────────

resource "aws_sns_topic_subscription" "warning_email" {
  for_each = toset(var.alert_email_endpoints)

  topic_arn = aws_sns_topic.warning.arn
  protocol  = "email"
  endpoint  = each.value
}

resource "aws_sns_topic_subscription" "critical_email" {
  for_each = toset(var.alert_email_endpoints)

  topic_arn = aws_sns_topic.critical.arn
  protocol  = "email"
  endpoint  = each.value
}
