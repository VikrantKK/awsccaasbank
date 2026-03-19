provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project            = var.project_name
      Environment        = var.environment
      Owner              = "platform-engineering"
      CostCenter         = "cc-contact-center"
      DataClassification = "confidential"
      ManagedBy          = "terraform"
    }
  }
}
