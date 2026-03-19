###############################################################################
# Kinesis Data Streams & Firehose — Real-Time Analytics
# CTR and Agent Events streaming for Westpac CCaaS
###############################################################################

# ---------------------------------------------------------------------------
# Contact Trace Records (CTR) Kinesis Data Stream
# ---------------------------------------------------------------------------
resource "aws_kinesis_stream" "ctr_stream" {
  name             = "${var.project_name}-${var.environment}-ctr-stream"
  retention_period = 168 # 7 days

  # Shard count is only used when stream mode is PROVISIONED
  shard_count = var.kinesis_on_demand ? null : var.kinesis_shard_count

  encryption_type = "KMS"
  kms_key_id      = var.storage_kms_key_arn

  stream_mode_details {
    stream_mode = var.kinesis_on_demand ? "ON_DEMAND" : "PROVISIONED"
  }

  tags = var.tags
}

# ---------------------------------------------------------------------------
# Agent Events Kinesis Data Stream
# ---------------------------------------------------------------------------
resource "aws_kinesis_stream" "agent_events_stream" {
  name             = "${var.project_name}-${var.environment}-agent-events-stream"
  retention_period = 168 # 7 days

  shard_count = var.kinesis_on_demand ? null : var.kinesis_shard_count

  encryption_type = "KMS"
  kms_key_id      = var.storage_kms_key_arn

  stream_mode_details {
    stream_mode = var.kinesis_on_demand ? "ON_DEMAND" : "PROVISIONED"
  }

  tags = var.tags
}

# ---------------------------------------------------------------------------
# IAM Role for Kinesis Firehose
# ---------------------------------------------------------------------------
resource "aws_iam_role" "firehose_role" {
  name = "${var.project_name}-${var.environment}-firehose-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "firehose.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "firehose_policy" {
  name = "${var.project_name}-${var.environment}-firehose-policy"
  role = aws_iam_role.firehose_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kinesis:DescribeStream",
          "kinesis:GetShardIterator",
          "kinesis:GetRecords",
          "kinesis:ListShards"
        ]
        Resource = aws_kinesis_stream.ctr_stream.arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:AbortMultipartUpload",
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:PutObject"
        ]
        Resource = [
          "arn:aws:s3:::${var.recordings_bucket_name}",
          "arn:aws:s3:::${var.recordings_bucket_name}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = var.storage_kms_key_arn
      }
    ]
  })
}

# ---------------------------------------------------------------------------
# Kinesis Firehose — CTR to S3
# ---------------------------------------------------------------------------
resource "aws_kinesis_firehose_delivery_stream" "ctr_to_s3" {
  name        = "${var.project_name}-${var.environment}-ctr-firehose"
  destination = "extended_s3"

  kinesis_source_configuration {
    kinesis_stream_arn = aws_kinesis_stream.ctr_stream.arn
    role_arn           = aws_iam_role.firehose_role.arn
  }

  extended_s3_configuration {
    role_arn   = aws_iam_role.firehose_role.arn
    bucket_arn = "arn:aws:s3:::${var.recordings_bucket_name}"

    prefix              = "ctr-data/"
    error_output_prefix = "ctr-errors/"

    buffering_size     = 5
    buffering_interval = 300
    compression_format = "GZIP"
  }

  tags = var.tags
}

# ---------------------------------------------------------------------------
# Connect Instance Storage Config — CTR to Kinesis
# ---------------------------------------------------------------------------
resource "aws_connect_instance_storage_config" "ctr_kinesis" {
  instance_id   = aws_connect_instance.this.id
  resource_type = "CONTACT_TRACE_RECORDS"

  storage_config {
    storage_type = "KINESIS_STREAM"

    kinesis_stream_config {
      stream_arn = aws_kinesis_stream.ctr_stream.arn
    }
  }
}

# ---------------------------------------------------------------------------
# Connect Instance Storage Config — Agent Events to Kinesis
# ---------------------------------------------------------------------------
resource "aws_connect_instance_storage_config" "agent_events_kinesis" {
  instance_id   = aws_connect_instance.this.id
  resource_type = "AGENT_EVENTS"

  storage_config {
    storage_type = "KINESIS_STREAM"

    kinesis_stream_config {
      stream_arn = aws_kinesis_stream.agent_events_stream.arn
    }
  }
}
