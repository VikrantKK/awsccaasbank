# ------------------------------------------------------------------------------
# Recordings — Glacier transition + 7-year retention (APRA CPS 234)
# ------------------------------------------------------------------------------

resource "aws_s3_bucket_lifecycle_configuration" "recordings" {
  bucket = aws_s3_bucket.recordings.id

  rule {
    id     = "archive-and-expire-recordings"
    status = "Enabled"

    transition {
      days          = var.recording_glacier_days
      storage_class = "GLACIER"
    }

    expiration {
      days = var.recording_retention_days
    }
  }

  rule {
    id     = "abort-incomplete-multipart"
    status = "Enabled"
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# ------------------------------------------------------------------------------
# Transcripts — same lifecycle as recordings
# ------------------------------------------------------------------------------

resource "aws_s3_bucket_lifecycle_configuration" "transcripts" {
  bucket = aws_s3_bucket.transcripts.id

  rule {
    id     = "archive-and-expire-transcripts"
    status = "Enabled"

    transition {
      days          = var.recording_glacier_days
      storage_class = "GLACIER"
    }

    expiration {
      days = var.recording_retention_days
    }
  }

  rule {
    id     = "abort-incomplete-multipart"
    status = "Enabled"
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# ------------------------------------------------------------------------------
# Exports — shorter retention, no archival tier
# ------------------------------------------------------------------------------

resource "aws_s3_bucket_lifecycle_configuration" "exports" {
  bucket = aws_s3_bucket.exports.id

  rule {
    id     = "expire-exports"
    status = "Enabled"

    expiration {
      days = var.export_retention_days
    }
  }

  rule {
    id     = "abort-incomplete-multipart"
    status = "Enabled"
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}
