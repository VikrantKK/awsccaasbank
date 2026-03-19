# ------------------------------------------------------------------------------
# S3 Bucket ARNs
# ------------------------------------------------------------------------------

output "recordings_bucket_arn" {
  description = "ARN of the call recordings S3 bucket"
  value       = aws_s3_bucket.recordings.arn
}

output "transcripts_bucket_arn" {
  description = "ARN of the transcripts S3 bucket"
  value       = aws_s3_bucket.transcripts.arn
}

output "exports_bucket_arn" {
  description = "ARN of the report exports S3 bucket"
  value       = aws_s3_bucket.exports.arn
}

# ------------------------------------------------------------------------------
# S3 Bucket IDs (names)
# ------------------------------------------------------------------------------

output "recordings_bucket_id" {
  description = "Name/ID of the call recordings S3 bucket"
  value       = aws_s3_bucket.recordings.id
}

output "transcripts_bucket_id" {
  description = "Name/ID of the transcripts S3 bucket"
  value       = aws_s3_bucket.transcripts.id
}

output "exports_bucket_id" {
  description = "Name/ID of the report exports S3 bucket"
  value       = aws_s3_bucket.exports.id
}

# ------------------------------------------------------------------------------
# DynamoDB Table ARNs
# ------------------------------------------------------------------------------

output "contact_records_table_arn" {
  description = "ARN of the contact records DynamoDB table"
  value       = aws_dynamodb_table.contact_records.arn
}

output "session_data_table_arn" {
  description = "ARN of the session data DynamoDB table"
  value       = aws_dynamodb_table.session_data.arn
}

# ------------------------------------------------------------------------------
# DynamoDB Table Names
# ------------------------------------------------------------------------------

output "contact_records_table_name" {
  description = "Name of the contact records DynamoDB table"
  value       = aws_dynamodb_table.contact_records.name
}

output "session_data_table_name" {
  description = "Name of the session data DynamoDB table"
  value       = aws_dynamodb_table.session_data.name
}
