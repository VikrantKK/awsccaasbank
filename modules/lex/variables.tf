variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "project_name" {
  description = "Project name used as a prefix for resource naming"
  type        = string
  default     = "westpac-ccaas"
}

variable "lex_service_role_arn" {
  description = "IAM role ARN for the Lex V2 bot service-linked role"
  type        = string
}

variable "logs_kms_key_arn" {
  description = "KMS key ARN for encrypting Lex conversation logs (APRA CPS 234)"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources in this module"
  type        = map(string)
  default     = {}
}
