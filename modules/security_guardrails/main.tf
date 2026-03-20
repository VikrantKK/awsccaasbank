################################################################################
# AWS Config — APRA CPS 234 / CPG 234 Compliance Recording
################################################################################

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# ---------------------------------------------------------------------------
# Configuration Recorder
# ---------------------------------------------------------------------------
resource "aws_config_configuration_recorder" "this" {
  name     = "${local.name_prefix}-config-recorder"
  role_arn = aws_iam_service_linked_role.config.arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

resource "aws_iam_service_linked_role" "config" {
  aws_service_name = "config.amazonaws.com"
  description      = "Service-linked role for AWS Config — ${local.name_prefix}"
}

# ---------------------------------------------------------------------------
# Delivery Channel
# ---------------------------------------------------------------------------
resource "aws_config_delivery_channel" "this" {
  name           = "${local.name_prefix}-config-delivery"
  s3_bucket_name = var.config_bucket_name
  sns_topic_arn  = var.config_sns_topic_arn != "" ? var.config_sns_topic_arn : null

  snapshot_delivery_properties {
    delivery_frequency = "TwentyFour_Hours"
  }

  depends_on = [aws_config_configuration_recorder.this]
}

# ---------------------------------------------------------------------------
# Recorder Status — enable recording
# ---------------------------------------------------------------------------
resource "aws_config_configuration_recorder_status" "this" {
  name       = aws_config_configuration_recorder.this.name
  is_enabled = true

  depends_on = [aws_config_delivery_channel.this]
}
