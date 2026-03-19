################################################################################
# AWS Organizations Tag Policy — Mandatory Tag Enforcement
# Requires AWS Organizations access; gated behind var.enable_tag_policy
################################################################################

resource "aws_organizations_policy" "mandatory_tags" {
  count = var.enable_tag_policy ? 1 : 0

  name        = "${local.name_prefix}-mandatory-tag-policy"
  description = "APRA CPS 234 compliant tag policy enforcing mandatory tags for Westpac CCaaS resources"
  type        = "TAG_POLICY"

  content = jsonencode({
    tags = {
      Project = {
        tag_key = {
          "@@assign" = "Project"
        }
        enforced_for = {
          "@@assign" = ["*"]
        }
      }
      Environment = {
        tag_key = {
          "@@assign" = "Environment"
        }
        tag_value = {
          "@@assign" = ["dev", "staging", "uat", "prod"]
        }
        enforced_for = {
          "@@assign" = ["*"]
        }
      }
      Owner = {
        tag_key = {
          "@@assign" = "Owner"
        }
        enforced_for = {
          "@@assign" = ["*"]
        }
      }
      CostCenter = {
        tag_key = {
          "@@assign" = "CostCenter"
        }
        enforced_for = {
          "@@assign" = ["*"]
        }
      }
      DataClassification = {
        tag_key = {
          "@@assign" = "DataClassification"
        }
        tag_value = {
          "@@assign" = ["Public", "Internal", "Confidential", "Restricted"]
        }
        enforced_for = {
          "@@assign" = ["*"]
        }
      }
      ManagedBy = {
        tag_key = {
          "@@assign" = "ManagedBy"
        }
        enforced_for = {
          "@@assign" = ["*"]
        }
      }
    }
  })

  tags = var.tags
}
