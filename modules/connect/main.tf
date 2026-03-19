###############################################################################
# Amazon Connect Instance — Westpac CCaaS
# APRA CPS 234 — SAML identity federation, encrypted storage, ap-southeast-2
###############################################################################

resource "aws_connect_instance" "this" {
  instance_alias           = "${var.project_name}-${var.environment}"
  identity_management_type = "SAML"
  inbound_calls_enabled    = true
  outbound_calls_enabled   = true

  tags = var.tags
}

# ---------------------------------------------------------------------------
# Instance storage — Call Recordings (S3 + KMS encryption)
# ---------------------------------------------------------------------------
resource "aws_connect_instance_storage_config" "call_recordings" {
  instance_id   = aws_connect_instance.this.id
  resource_type = "CALL_RECORDINGS"

  storage_config {
    storage_type = "S3"

    s3_config {
      bucket_name   = var.recordings_bucket_name
      bucket_prefix = "call-recordings/"

      encryption_config {
        encryption_type = "KMS"
        key_id          = var.storage_kms_key_arn
      }
    }
  }
}

# ---------------------------------------------------------------------------
# Instance storage — Chat Transcripts (S3)
# ---------------------------------------------------------------------------
resource "aws_connect_instance_storage_config" "chat_transcripts" {
  instance_id   = aws_connect_instance.this.id
  resource_type = "CHAT_TRANSCRIPTS"

  storage_config {
    storage_type = "S3"

    s3_config {
      bucket_name   = var.transcripts_bucket_name
      bucket_prefix = "chat-transcripts/"

      encryption_config {
        encryption_type = "KMS"
        key_id          = var.storage_kms_key_arn
      }
    }
  }
}
