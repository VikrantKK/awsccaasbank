variable "environment" {
  description = "Deployment environment (e.g. dev, uat, prod)"
  type        = string
}

variable "project_name" {
  description = "Project name used in resource naming"
  type        = string
  default     = "westpac-ccaas"
}

variable "storage_kms_key_arn" {
  description = "ARN of the customer-managed KMS key for S3 bucket encryption"
  type        = string
}

variable "dynamodb_kms_key_arn" {
  description = "ARN of the customer-managed KMS key for DynamoDB table encryption"
  type        = string
}

variable "dynamodb_billing_mode" {
  description = "DynamoDB billing mode (PAY_PER_REQUEST or PROVISIONED)"
  type        = string
  default     = "PAY_PER_REQUEST"
}

variable "recording_glacier_days" {
  description = "Number of days before transitioning recordings to Glacier"
  type        = number
  default     = 90
}

variable "recording_retention_days" {
  description = "Number of days to retain recordings before expiry (7 years)"
  type        = number
  default     = 2555
}

variable "export_retention_days" {
  description = "Number of days to retain report exports before expiry"
  type        = number
  default     = 90
}

variable "tags" {
  description = "Tags to apply to all resources in this module"
  type        = map(string)
}
