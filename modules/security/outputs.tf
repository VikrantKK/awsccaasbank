###############################################################################
# KMS Key ARNs
###############################################################################

output "connect_kms_key_arn" {
  description = "ARN of the KMS key for Amazon Connect encryption"
  value       = aws_kms_key.connect_key.arn
}

output "storage_kms_key_arn" {
  description = "ARN of the KMS key for S3 storage encryption"
  value       = aws_kms_key.storage_key.arn
}

output "dynamodb_kms_key_arn" {
  description = "ARN of the KMS key for DynamoDB encryption"
  value       = aws_kms_key.dynamodb_key.arn
}

output "logs_kms_key_arn" {
  description = "ARN of the KMS key for CloudWatch Logs encryption"
  value       = aws_kms_key.logs_key.arn
}

###############################################################################
# KMS Key IDs
###############################################################################

output "connect_kms_key_id" {
  description = "ID of the KMS key for Amazon Connect encryption"
  value       = aws_kms_key.connect_key.key_id
}

output "storage_kms_key_id" {
  description = "ID of the KMS key for S3 storage encryption"
  value       = aws_kms_key.storage_key.key_id
}

output "dynamodb_kms_key_id" {
  description = "ID of the KMS key for DynamoDB encryption"
  value       = aws_kms_key.dynamodb_key.key_id
}

output "logs_kms_key_id" {
  description = "ID of the KMS key for CloudWatch Logs encryption"
  value       = aws_kms_key.logs_key.key_id
}

###############################################################################
# IAM Role ARNs
###############################################################################

output "connect_service_role_arn" {
  description = "ARN of the IAM role for Amazon Connect"
  value       = aws_iam_role.connect_service_role.arn
}

output "connect_service_role_name" {
  description = "Name of the IAM role for Amazon Connect"
  value       = aws_iam_role.connect_service_role.name
}

output "lambda_execution_role_arn" {
  description = "ARN of the IAM execution role for Lambda functions"
  value       = aws_iam_role.lambda_execution_role.arn
}

output "lambda_execution_role_name" {
  description = "Name of the IAM execution role for Lambda functions"
  value       = aws_iam_role.lambda_execution_role.name
}

output "lex_service_role_arn" {
  description = "ARN of the IAM role for Lex V2 bots"
  value       = aws_iam_role.lex_service_role.arn
}

output "lex_service_role_name" {
  description = "Name of the IAM role for Lex V2 bots"
  value       = aws_iam_role.lex_service_role.name
}
