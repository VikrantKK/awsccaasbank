###############################################################################
# IAM — Per-function execution roles (least privilege, APRA CPS 234)
###############################################################################

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# -----------------------------------------------------------------------------
# IAM Roles (one per function)
# -----------------------------------------------------------------------------

resource "aws_iam_role" "lambda" {
  for_each = local.functions

  name = "${var.project_name}-${each.key}-role-${var.environment}"

  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json

  tags = merge(var.tags, {
    Name     = "${var.project_name}-${each.key}-role-${var.environment}"
    Function = each.key
  })
}

# -----------------------------------------------------------------------------
# VPC Access — AWSLambdaVPCAccessExecutionRole managed policy
# -----------------------------------------------------------------------------

resource "aws_iam_role_policy_attachment" "lambda_vpc" {
  for_each = local.functions

  role       = aws_iam_role.lambda[each.key].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# -----------------------------------------------------------------------------
# Inline policy — CloudWatch Logs, DynamoDB, SQS DLQ (scoped per function)
# -----------------------------------------------------------------------------

data "aws_iam_policy_document" "lambda_permissions" {
  for_each = local.functions

  # CloudWatch Logs — scoped to the function's own log group
  statement {
    sid    = "CloudWatchLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = [
      "arn:aws:logs:${local.region}:${local.account_id}:log-group:/aws/lambda/${var.project_name}-${each.key}-${var.environment}",
      "arn:aws:logs:${local.region}:${local.account_id}:log-group:/aws/lambda/${var.project_name}-${each.key}-${var.environment}:*",
    ]
  }

  # DynamoDB — GetItem, PutItem, Query on contact_records and session_data tables
  statement {
    sid    = "DynamoDBAccess"
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:Query",
    ]
    resources = [
      var.dynamodb_contact_table_arn,
      "${var.dynamodb_contact_table_arn}/index/*",
      var.dynamodb_session_table_arn,
      "${var.dynamodb_session_table_arn}/index/*",
    ]
  }

  # SQS — SendMessage to the function's own DLQ
  statement {
    sid    = "SQSDLQAccess"
    effect = "Allow"
    actions = [
      "sqs:SendMessage",
    ]
    resources = [
      aws_sqs_queue.dlq[each.key].arn,
    ]
  }
}

resource "aws_iam_role_policy" "lambda_permissions" {
  for_each = local.functions

  name   = "${var.project_name}-${each.key}-policy-${var.environment}"
  role   = aws_iam_role.lambda[each.key].id
  policy = data.aws_iam_policy_document.lambda_permissions[each.key].json
}
