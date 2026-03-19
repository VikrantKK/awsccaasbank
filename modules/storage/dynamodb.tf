# ------------------------------------------------------------------------------
# Contact Records Table — stores Amazon Connect contact trace records
# ------------------------------------------------------------------------------

resource "aws_dynamodb_table" "contact_records" {
  name         = "${var.project_name}-${var.environment}-contact-records"
  billing_mode = var.dynamodb_billing_mode

  hash_key  = "contactId"
  range_key = "timestamp"

  attribute {
    name = "contactId"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "S"
  }

  ttl {
    attribute_name = "expiry"
    enabled        = true
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = var.dynamodb_kms_key_arn
  }

  tags = merge(var.tags, {
    Name    = "${var.project_name}-${var.environment}-contact-records"
    Purpose = "contact-records"
  })
}

# ------------------------------------------------------------------------------
# Session Data Table — stores active session state
# ------------------------------------------------------------------------------

resource "aws_dynamodb_table" "session_data" {
  name         = "${var.project_name}-${var.environment}-session-data"
  billing_mode = var.dynamodb_billing_mode

  hash_key = "sessionId"

  attribute {
    name = "sessionId"
    type = "S"
  }

  ttl {
    attribute_name = "expiry"
    enabled        = true
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = var.dynamodb_kms_key_arn
  }

  tags = merge(var.tags, {
    Name    = "${var.project_name}-${var.environment}-session-data"
    Purpose = "session-data"
  })
}
