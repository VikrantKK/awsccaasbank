variable "environment" {
  description = "Deployment environment (e.g. dev, staging, prod)"
  type        = string
}

variable "project_name" {
  description = "Project name used for resource naming and tagging"
  type        = string
  default     = "awsccaasbank-ccaas"
}

variable "config_bucket_name" {
  description = "S3 bucket name for AWS Config delivery channel"
  type        = string
}

variable "config_sns_topic_arn" {
  description = "SNS topic ARN for AWS Config delivery notifications"
  type        = string
  default     = ""
}

variable "cloudtrail_bucket_name" {
  description = "S3 bucket name for CloudTrail log delivery"
  type        = string
}

variable "cloudtrail_kms_key_arn" {
  description = "KMS key ARN used to encrypt CloudTrail logs"
  type        = string
}

variable "cloudtrail_log_group_arn" {
  description = "CloudWatch Logs group ARN for CloudTrail integration"
  type        = string
  default     = ""
}

variable "enable_tag_policy" {
  description = "Enable AWS Organizations tag policy enforcement (requires Organizations access)"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Common tags applied to all resources in this module"
  type        = map(string)
}
