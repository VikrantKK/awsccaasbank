################################################################################
# CloudWatch Alarms — CCaaS Platform
################################################################################

# ── Queue Wait Time — Warning ─────────────────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "queue_wait_time_warning" {
  alarm_name          = "${var.project_name}-${var.environment}-queue-size-warning"
  alarm_description   = "Connect queue size exceeds 5 — warning threshold"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  period              = 60
  threshold           = 5
  statistic           = "Maximum"
  namespace           = "AWS/Connect"
  metric_name         = "QueueSize"
  treat_missing_data  = "notBreaching"
  actions_enabled     = var.alarm_actions_enabled

  dimensions = {
    InstanceId = var.connect_instance_id
  }

  alarm_actions = [aws_sns_topic.warning.arn]
  ok_actions    = [aws_sns_topic.warning.arn]

  tags = var.tags
}

# ── Queue Wait Time — Critical ────────────────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "queue_wait_time_critical" {
  alarm_name          = "${var.project_name}-${var.environment}-queue-size-critical"
  alarm_description   = "Connect queue size exceeds 15 — critical threshold"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  period              = 60
  threshold           = 15
  statistic           = "Maximum"
  namespace           = "AWS/Connect"
  metric_name         = "QueueSize"
  treat_missing_data  = "notBreaching"
  actions_enabled     = var.alarm_actions_enabled

  dimensions = {
    InstanceId = var.connect_instance_id
  }

  alarm_actions = [aws_sns_topic.critical.arn]
  ok_actions    = [aws_sns_topic.critical.arn]

  tags = var.tags
}

# ── Lambda Error Rate (per function) ──────────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "lambda_error_rate" {
  for_each = toset(var.lambda_function_names)

  alarm_name          = "${var.project_name}-${var.environment}-lambda-errors-${each.value}"
  alarm_description   = "Lambda function ${each.value} error count exceeds 1"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  period              = 60
  threshold           = 1
  statistic           = "Sum"
  namespace           = "AWS/Lambda"
  metric_name         = "Errors"
  treat_missing_data  = "notBreaching"
  actions_enabled     = var.alarm_actions_enabled

  dimensions = {
    FunctionName = each.value
  }

  alarm_actions = [aws_sns_topic.warning.arn]
  ok_actions    = [aws_sns_topic.warning.arn]

  tags = var.tags
}

# ── DynamoDB Throttle (per table) ─────────────────────────────────────────────

resource "aws_cloudwatch_metric_alarm" "dynamodb_throttle" {
  for_each = toset(var.dynamodb_table_names)

  alarm_name          = "${var.project_name}-${var.environment}-dynamodb-throttle-${each.value}"
  alarm_description   = "DynamoDB table ${each.value} is experiencing throttled requests"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  period              = 60
  threshold           = 0
  statistic           = "Sum"
  namespace           = "AWS/DynamoDB"
  metric_name         = "ThrottledRequests"
  treat_missing_data  = "notBreaching"
  actions_enabled     = var.alarm_actions_enabled

  dimensions = {
    TableName = each.value
  }

  alarm_actions = [aws_sns_topic.critical.arn]
  ok_actions    = [aws_sns_topic.critical.arn]

  tags = var.tags
}
