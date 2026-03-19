output "config_recorder_id" {
  description = "ID of the AWS Config configuration recorder"
  value       = aws_config_configuration_recorder.this.id
}

output "cloudtrail_arn" {
  description = "ARN of the CloudTrail trail"
  value       = aws_cloudtrail.this.arn
}

output "s3_account_public_access_block_id" {
  description = "ID of the S3 account-level public access block"
  value       = aws_s3_account_public_access_block.this.id
}
