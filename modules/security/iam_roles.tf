###############################################################################
# IAM Role — Amazon Connect service role
###############################################################################

data "aws_iam_policy_document" "connect_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["connect.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [local.account_id]
    }
  }
}

resource "aws_iam_role" "connect_service_role" {
  name = "${local.name_prefix}-connect-service-role"

  assume_role_policy = data.aws_iam_policy_document.connect_assume_role.json

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-connect-service-role"
  })
}

###############################################################################
# IAM Role — Lambda execution role
###############################################################################

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [local.account_id]
    }
  }
}

resource "aws_iam_role" "lambda_execution_role" {
  name = "${local.name_prefix}-lambda-execution-role"

  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-lambda-execution-role"
  })
}

# Attach AWS managed policy for Lambda VPC access
resource "aws_iam_role_policy_attachment" "lambda_vpc_access" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:${local.partition}:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

###############################################################################
# IAM Role — Lex V2 service role
###############################################################################

data "aws_iam_policy_document" "lex_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lexv2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [local.account_id]
    }
  }
}

resource "aws_iam_role" "lex_service_role" {
  name = "${local.name_prefix}-lex-service-role"

  assume_role_policy = data.aws_iam_policy_document.lex_assume_role.json

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-lex-service-role"
  })
}
