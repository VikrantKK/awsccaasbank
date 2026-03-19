################################################################################
# Lex V2 Bot — Westpac IVR Self-Service
# Provides automated self-service intents for Amazon Connect contact flows.
# Locale: en_AU | Compliance: APRA CPS 234 (encryption at rest via KMS)
################################################################################

resource "aws_lexv2models_bot" "self_service" {
  name        = "${var.project_name}-${var.environment}-self-service"
  description = "Westpac IVR self-service bot for Amazon Connect (${var.environment})"

  role_arn                    = var.lex_service_role_arn
  idle_session_ttl_in_seconds = 300

  data_privacy {
    child_directed = false
  }

  tags = var.tags
}

# ---------------------------------------------------------------------------
# Bot Locale — Australian English
# ---------------------------------------------------------------------------
resource "aws_lexv2models_bot_locale" "en_au" {
  bot_id      = aws_lexv2models_bot.self_service.id
  bot_version = "DRAFT"
  locale_id   = "en_AU"

  n_lu_intent_confidence_threshold = 0.40

  description = "Australian English locale for Westpac self-service bot"
}

# ---------------------------------------------------------------------------
# Bot Version — created after all intents are defined
# ---------------------------------------------------------------------------
resource "aws_lexv2models_bot_version" "current" {
  bot_id      = aws_lexv2models_bot.self_service.id
  description = "Managed by Terraform — ${var.environment}"

  locale_specification = {
    "en_AU" = {
      source_bot_version = "DRAFT"
    }
  }

  depends_on = [
    aws_lexv2models_intent.check_balance,
    aws_lexv2models_intent.report_lost_card,
    aws_lexv2models_intent.branch_hours,
    aws_lexv2models_intent.fallback,
  ]
}

# ---------------------------------------------------------------------------
# NOTE: aws_lexv2models_bot_alias is not yet available in the hashicorp/aws
# provider. The Connect bot association uses the bot ID + DRAFT version.
# When the resource becomes available (or via the awscc provider), add an
# alias resource here for production-grade version pinning.
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# CloudWatch Log Group for conversation logs (APRA CPS 234 — encrypted)
# ---------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "lex_conversation_logs" {
  name              = "/aws/lex/${var.project_name}-${var.environment}-self-service"
  retention_in_days = 365
  kms_key_id        = var.logs_kms_key_arn

  tags = var.tags
}
