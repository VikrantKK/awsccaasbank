variable "environment" {
  description = "Deployment environment (e.g. dev, uat, prod)"
  type        = string
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "awsccaasbank-ccaas"
}

variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "ap-southeast-2"
}

variable "recordings_bucket_name" {
  description = "S3 bucket name for call recordings storage (APRA CPS 234 compliant)"
  type        = string
}

variable "transcripts_bucket_name" {
  description = "S3 bucket name for chat transcripts storage"
  type        = string
}

variable "storage_kms_key_arn" {
  description = "KMS key ARN for encrypting call recordings at rest"
  type        = string
}

variable "contact_flows_path" {
  description = "Path to contact flow JSON definition files"
  type        = string
  default     = "../../contact_flows"
}

variable "phone_numbers" {
  description = "Map of phone numbers to provision (key = logical name, value = country_code and type)"
  type = map(object({
    country_code = string
    type         = string
  }))
  default = {}
}

variable "lambda_function_arns" {
  description = "List of Lambda function ARNs to associate with the Connect instance"
  type        = list(string)
  default     = []
}

variable "lex_bot_alias_arn" {
  description = "Lex V2 bot alias ARN for bot association (empty to skip)"
  type        = string
  default     = ""
}


variable "kinesis_shard_count" {
  description = "Number of shards for Kinesis Data Streams (used when kinesis_on_demand is false)"
  type        = number
  default     = 1
}

variable "kinesis_on_demand" {
  description = "Use ON_DEMAND capacity mode for Kinesis streams (true) or PROVISIONED (false)"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
}
