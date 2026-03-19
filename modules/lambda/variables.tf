variable "environment" {
  description = "Deployment environment (e.g. dev, staging, prod)"
  type        = string
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "westpac-ccaas"
}

variable "subnet_ids" {
  description = "List of VPC subnet IDs for Lambda function deployment"
  type        = list(string)
}

variable "lambda_security_group_id" {
  description = "Security group ID for Lambda functions"
  type        = string
}

variable "lambda_kms_key_arn" {
  description = "KMS key ARN for Lambda environment variable encryption"
  type        = string
}

variable "logs_kms_key_arn" {
  description = "KMS key ARN for CloudWatch Logs encryption"
  type        = string
}

variable "dynamodb_contact_table_arn" {
  description = "ARN of the DynamoDB contact records table"
  type        = string
}

variable "dynamodb_session_table_arn" {
  description = "ARN of the DynamoDB session data table"
  type        = string
}

variable "dynamodb_contact_table_name" {
  description = "Name of the DynamoDB contact records table"
  type        = string
}

variable "dynamodb_session_table_name" {
  description = "Name of the DynamoDB session data table"
  type        = string
}

variable "connect_instance_id" {
  description = "Amazon Connect instance ID"
  type        = string
  default     = ""
}

variable "reserved_concurrency" {
  description = "Reserved concurrent executions for each Lambda function"
  type        = number
  default     = 5
}

variable "log_retention_days" {
  description = "CloudWatch Log Group retention period in days"
  type        = number
  default     = 365
}

variable "code_signing_profile_arns" {
  description = "List of signing profile version ARNs for Lambda code signing (empty to skip)"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
}
