###############################################################################
# Lambda Module — Amazon Connect CCaaS Integration Functions
# Region: ap-southeast-2 | Compliance: APRA CPS 234
# All functions deployed within VPC with KMS encryption
###############################################################################

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name

  functions = {
    cti_adapter = {
      description = "CTI adapter integration function for Amazon Connect"
      timeout     = 30
      memory_size = 256
    }
    crm_lookup = {
      description = "Customer CRM lookup function for Amazon Connect"
      timeout     = 10
      memory_size = 128
    }
    post_call_survey = {
      description = "Post-call survey trigger function for Amazon Connect"
      timeout     = 15
      memory_size = 128
    }
  }
}

# -----------------------------------------------------------------------------
# Source code archives
# -----------------------------------------------------------------------------

data "archive_file" "lambda" {
  for_each = local.functions

  type        = "zip"
  source_dir  = "${path.module}/src/${each.key}/"
  output_path = "${path.module}/build/${each.key}.zip"
}

# -----------------------------------------------------------------------------
# Dead Letter Queues (one per function)
# -----------------------------------------------------------------------------

resource "aws_sqs_queue" "dlq" {
  for_each = local.functions

  name                       = "${var.project_name}-${each.key}-dlq-${var.environment}"
  message_retention_seconds  = 1209600 # 14 days
  kms_master_key_id          = var.lambda_kms_key_arn
  kms_data_key_reuse_period_seconds = 300

  tags = merge(var.tags, {
    Name     = "${var.project_name}-${each.key}-dlq-${var.environment}"
    Function = each.key
  })
}

# -----------------------------------------------------------------------------
# CloudWatch Log Groups
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "lambda" {
  for_each = local.functions

  name              = "/aws/lambda/${var.project_name}-${each.key}-${var.environment}"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.logs_kms_key_arn

  tags = merge(var.tags, {
    Name     = "${var.project_name}-${each.key}-logs-${var.environment}"
    Function = each.key
  })
}

# -----------------------------------------------------------------------------
# Lambda Functions
# -----------------------------------------------------------------------------

resource "aws_lambda_function" "this" {
  for_each = local.functions

  function_name = "${var.project_name}-${each.key}-${var.environment}"
  description   = each.value.description
  role          = aws_iam_role.lambda[each.key].arn

  filename         = data.archive_file.lambda[each.key].output_path
  source_code_hash = data.archive_file.lambda[each.key].output_base64sha256
  runtime          = "python3.12"
  handler          = "index.handler"
  timeout          = each.value.timeout
  memory_size      = each.value.memory_size

  reserved_concurrent_executions = var.reserved_concurrency

  kms_key_arn = var.lambda_kms_key_arn

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = [var.lambda_security_group_id]
  }

  environment {
    variables = {
      DYNAMODB_CONTACT_TABLE = var.dynamodb_contact_table_name
      DYNAMODB_SESSION_TABLE = var.dynamodb_session_table_name
      CONNECT_INSTANCE_ID    = var.connect_instance_id
      ENVIRONMENT            = var.environment
    }
  }

  dead_letter_config {
    target_arn = aws_sqs_queue.dlq[each.key].arn
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_vpc,
    aws_iam_role_policy.lambda_permissions,
    aws_cloudwatch_log_group.lambda,
  ]

  tags = merge(var.tags, {
    Name     = "${var.project_name}-${each.key}-${var.environment}"
    Function = each.key
  })
}
