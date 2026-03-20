variable "environment" {
  description = "Deployment environment (e.g. dev, staging, prod)"
  type        = string
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "awsccaasbank-ccaas"
}

variable "connect_instance_id" {
  description = "Amazon Connect instance ID"
  type        = string
}

variable "queues" {
  description = "Map of Amazon Connect queues to create"
  type = map(object({
    description  = string
    max_contacts = number
    hours_type   = string
  }))
  default = {
    retail_banking = {
      description  = "Retail Banking customer queue"
      max_contacts = 50
      hours_type   = "standard_hours"
    }
    business_banking = {
      description  = "Business Banking customer queue"
      max_contacts = 30
      hours_type   = "extended_hours"
    }
    fraud = {
      description  = "Fraud and security investigations queue"
      max_contacts = 20
      hours_type   = "twentyfour_seven"
    }
  }
}

variable "routing_profiles" {
  description = "Map of routing profiles to create"
  type = map(object({
    description = string
    queue_priorities = map(object({
      priority = number
      delay    = number
    }))
  }))
  default = {
    default_agent = {
      description = "Default agent routing profile"
      queue_priorities = {
        retail_banking = {
          priority = 1
          delay    = 0
        }
        business_banking = {
          priority = 2
          delay    = 0
        }
        fraud = {
          priority = 1
          delay    = 0
        }
      }
    }
  }
}

variable "quick_connects" {
  description = "Map of quick connects to create"
  type = map(object({
    queue_key       = string
    contact_flow_id = string
  }))
  default = {}
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
}
