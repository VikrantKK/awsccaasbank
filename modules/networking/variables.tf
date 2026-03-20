variable "environment" {
  description = "Deployment environment (e.g. dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "project_name" {
  description = "Project name used for resource naming and tagging"
  type        = string
  default     = "awsccaasbank-ccaas"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr must be a valid CIDR block."
  }
}

variable "nat_gateway_count" {
  description = "Number of NAT Gateways to deploy (1 for dev, 3 for prod HA)"
  type        = number
  default     = 1

  validation {
    condition     = contains([1, 2, 3], var.nat_gateway_count)
    error_message = "nat_gateway_count must be 1, 2, or 3."
  }
}

variable "logs_kms_key_arn" {
  description = "KMS key ARN for encrypting VPC Flow Logs CloudWatch Log Group"
  type        = string
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
