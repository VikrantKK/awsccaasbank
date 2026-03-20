################################################################################
# Variables — Monitoring Module
################################################################################

variable "environment" {
  description = "Deployment environment (e.g. dev, uat, prod)"
  type        = string
}

variable "project_name" {
  description = "Project name used as a prefix for all resources"
  type        = string
  default     = "awsccaasbank-ccaas"
}

variable "logs_kms_key_arn" {
  description = "ARN of the KMS key used to encrypt log groups and SNS topics"
  type        = string
}

variable "connect_instance_id" {
  description = "Amazon Connect instance ID for metric dimensions"
  type        = string
  default     = ""
}

variable "lambda_function_names" {
  description = "List of Lambda function names to monitor"
  type        = list(string)
  default     = []
}

variable "dynamodb_table_names" {
  description = "List of DynamoDB table names to monitor"
  type        = list(string)
  default     = []
}

variable "alarm_actions_enabled" {
  description = "Whether alarm actions (SNS notifications) are enabled"
  type        = bool
  default     = true
}

variable "alert_email_endpoints" {
  description = "List of email addresses to subscribe to warning and critical SNS topics"
  type        = list(string)
  default     = []
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs (minimum 365 for APRA CPS 234)"
  type        = number
  default     = 365
}

variable "tags" {
  description = "Tags to apply to all resources in this module"
  type        = map(string)
}
