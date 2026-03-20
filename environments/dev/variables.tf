variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "awsccaasbank-ccaas"
}

variable "aws_region" {
  description = "AWS region — must be ap-southeast-2 for APRA CPS 234 compliance"
  type        = string
  default     = "ap-southeast-2"
}

# Networking
variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "nat_gateway_count" {
  description = "Number of NAT gateways (1 for dev, 3 for prod HA)"
  type        = number
  default     = 1
}

# Security
variable "kms_deletion_window_days" {
  description = "KMS key deletion waiting period in days"
  type        = number
  default     = 7
}

# Lambda
variable "lambda_reserved_concurrency" {
  description = "Reserved concurrent executions per Lambda function"
  type        = number
  default     = 5
}

# Storage
variable "dynamodb_billing_mode" {
  description = "DynamoDB billing mode (PAY_PER_REQUEST or PROVISIONED)"
  type        = string
  default     = "PAY_PER_REQUEST"
}

variable "recording_retention_days" {
  description = "Days to retain call recordings before deletion"
  type        = number
  default     = 30
}

variable "recording_glacier_days" {
  description = "Days before transitioning recordings to Glacier"
  type        = number
  default     = 90
}

# Connect
variable "phone_numbers" {
  description = "Phone numbers to claim for the Connect instance"
  type = map(object({
    country_code = string
    type         = string
  }))
  default = {}
}

# Monitoring
variable "alarm_actions_enabled" {
  description = "Whether CloudWatch alarm actions are enabled"
  type        = bool
  default     = false
}

variable "alert_email_endpoints" {
  description = "Email addresses for alarm notifications"
  type        = list(string)
  default     = []
}
