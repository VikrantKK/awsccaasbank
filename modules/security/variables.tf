variable "environment" {
  description = "Deployment environment (e.g. dev, uat, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "uat", "prod"], var.environment)
    error_message = "Environment must be one of: dev, uat, prod."
  }
}

variable "project_name" {
  description = "Project name used in resource naming"
  type        = string
  default     = "awsccaasbank-ccaas"
}

variable "aws_region" {
  description = "AWS region — restricted to ap-southeast-2 for APRA CPS 234 data sovereignty"
  type        = string
  default     = "ap-southeast-2"

  validation {
    condition     = var.aws_region == "ap-southeast-2"
    error_message = "Only ap-southeast-2 is permitted under APRA CPS 234 data sovereignty requirements."
  }
}

variable "kms_deletion_window_days" {
  description = "KMS key deletion waiting period in days (7-30)"
  type        = number
  default     = 14

  validation {
    condition     = var.kms_deletion_window_days >= 7 && var.kms_deletion_window_days <= 30
    error_message = "KMS deletion window must be between 7 and 30 days."
  }
}

variable "tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
}

variable "dynamodb_table_arns" {
  description = "ARNs of DynamoDB tables that Lambda functions may access"
  type        = list(string)
  default     = []
}

variable "s3_bucket_arns" {
  description = "ARNs of S3 buckets for recordings/transcripts that Lambda and Connect may access"
  type        = list(string)
  default     = []
}
