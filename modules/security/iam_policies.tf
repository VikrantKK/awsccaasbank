###############################################################################
# IAM Policy — Lambda execution (least privilege)
###############################################################################

data "aws_iam_policy_document" "lambda_policy" {
  # DynamoDB read/write on scoped tables
  statement {
    sid    = "DynamoDBAccess"
    effect = "Allow"

    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem",
      "dynamodb:Query",
      "dynamodb:Scan",
      "dynamodb:BatchGetItem",
      "dynamodb:BatchWriteItem",
    ]

    resources = length(var.dynamodb_table_arns) > 0 ? concat(
      var.dynamodb_table_arns,
      [for arn in var.dynamodb_table_arns : "${arn}/index/*"]
    ) : ["arn:${local.partition}:dynamodb:${var.aws_region}:${local.account_id}:table/${local.name_prefix}-*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.aws_region]
    }
  }

  # S3 read on recordings/transcripts buckets
  statement {
    sid    = "S3ReadAccess"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:ListBucket",
    ]

    resources = length(var.s3_bucket_arns) > 0 ? concat(
      var.s3_bucket_arns,
      [for arn in var.s3_bucket_arns : "${arn}/*"]
      ) : [
      "arn:${local.partition}:s3:::${local.name_prefix}-*",
      "arn:${local.partition}:s3:::${local.name_prefix}-*/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.aws_region]
    }
  }

  # KMS encrypt/decrypt with relevant keys
  statement {
    sid    = "KMSAccess"
    effect = "Allow"

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:GenerateDataKey",
      "kms:GenerateDataKeyWithoutPlaintext",
      "kms:DescribeKey",
    ]

    resources = [
      aws_kms_key.dynamodb_key.arn,
      aws_kms_key.storage_key.arn,
      aws_kms_key.logs_key.arn,
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.aws_region]
    }
  }

  # CloudWatch Logs
  statement {
    sid    = "CloudWatchLogsAccess"
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "arn:${local.partition}:logs:${var.aws_region}:${local.account_id}:log-group:/aws/lambda/${local.name_prefix}-*",
      "arn:${local.partition}:logs:${var.aws_region}:${local.account_id}:log-group:/aws/lambda/${local.name_prefix}-*:*",
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.aws_region]
    }
  }
}

resource "aws_iam_policy" "lambda_policy" {
  name        = "${local.name_prefix}-lambda-policy"
  description = "Least-privilege policy for CCaaS Lambda functions"
  policy      = data.aws_iam_policy_document.lambda_policy.json

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-lambda-policy"
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

###############################################################################
# IAM Policy — Amazon Connect service (least privilege)
###############################################################################

data "aws_iam_policy_document" "connect_policy" {
  # S3 put for recordings
  statement {
    sid    = "S3RecordingsPut"
    effect = "Allow"

    actions = [
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:GetBucketLocation",
    ]

    resources = length(var.s3_bucket_arns) > 0 ? concat(
      var.s3_bucket_arns,
      [for arn in var.s3_bucket_arns : "${arn}/*"]
      ) : [
      "arn:${local.partition}:s3:::${local.name_prefix}-*",
      "arn:${local.partition}:s3:::${local.name_prefix}-*/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.aws_region]
    }
  }

  # KMS encrypt/decrypt
  statement {
    sid    = "KMSAccess"
    effect = "Allow"

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:GenerateDataKey",
      "kms:GenerateDataKeyWithoutPlaintext",
      "kms:DescribeKey",
    ]

    resources = [
      aws_kms_key.connect_key.arn,
      aws_kms_key.storage_key.arn,
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.aws_region]
    }
  }

  # Lex runtime for bot integration
  statement {
    sid    = "LexRuntimeAccess"
    effect = "Allow"

    actions = [
      "lex:RecognizeText",
      "lex:RecognizeUtterance",
      "lex:StartConversation",
      "lex:DeleteSession",
      "lex:GetSession",
      "lex:PutSession",
    ]

    resources = [
      "arn:${local.partition}:lex:${var.aws_region}:${local.account_id}:bot-alias/${local.name_prefix}-*",
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.aws_region]
    }
  }
}

resource "aws_iam_policy" "connect_policy" {
  name        = "${local.name_prefix}-connect-policy"
  description = "Least-privilege policy for Amazon Connect service"
  policy      = data.aws_iam_policy_document.connect_policy.json

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-connect-policy"
  })
}

resource "aws_iam_role_policy_attachment" "connect_policy" {
  role       = aws_iam_role.connect_service_role.name
  policy_arn = aws_iam_policy.connect_policy.arn
}

###############################################################################
# IAM Policy — Lex V2 service (least privilege)
###############################################################################

data "aws_iam_policy_document" "lex_policy" {
  # CloudWatch Logs
  statement {
    sid    = "CloudWatchLogsAccess"
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "arn:${local.partition}:logs:${var.aws_region}:${local.account_id}:log-group:/aws/lex/${local.name_prefix}-*",
      "arn:${local.partition}:logs:${var.aws_region}:${local.account_id}:log-group:/aws/lex/${local.name_prefix}-*:*",
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.aws_region]
    }
  }
}

resource "aws_iam_policy" "lex_policy" {
  name        = "${local.name_prefix}-lex-policy"
  description = "Least-privilege policy for Lex V2 bots"
  policy      = data.aws_iam_policy_document.lex_policy.json

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-lex-policy"
  })
}

resource "aws_iam_role_policy_attachment" "lex_policy" {
  role       = aws_iam_role.lex_service_role.name
  policy_arn = aws_iam_policy.lex_policy.arn
}
