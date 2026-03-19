################################################################################
# CloudWatch Dashboard — CCaaS Observability
################################################################################

resource "aws_cloudwatch_dashboard" "ccaas" {
  dashboard_name = "${var.project_name}-${var.environment}-ccaas"

  dashboard_body = jsonencode({
    widgets = concat(
      # ── Amazon Connect Metrics ───────────────────────────────────────────
      [
        {
          type   = "metric"
          x      = 0
          y      = 0
          width  = 12
          height = 6
          properties = {
            title  = "Connect - Concurrent Calls"
            region = "ap-southeast-2"
            metrics = [
              ["AWS/Connect", "ConcurrentCalls", "InstanceId", var.connect_instance_id]
            ]
            period = 60
            stat   = "Maximum"
            view   = "timeSeries"
          }
        },
        {
          type   = "metric"
          x      = 12
          y      = 0
          width  = 12
          height = 6
          properties = {
            title  = "Connect - Calls Per Interval"
            region = "ap-southeast-2"
            metrics = [
              ["AWS/Connect", "CallsPerInterval", "InstanceId", var.connect_instance_id]
            ]
            period = 300
            stat   = "Sum"
            view   = "timeSeries"
          }
        },
        {
          type   = "metric"
          x      = 0
          y      = 6
          width  = 12
          height = 6
          properties = {
            title  = "Connect - Missed Calls"
            region = "ap-southeast-2"
            metrics = [
              ["AWS/Connect", "MissedCalls", "InstanceId", var.connect_instance_id]
            ]
            period = 300
            stat   = "Sum"
            view   = "timeSeries"
          }
        },
      ],

      # ── Queue Metrics ────────────────────────────────────────────────────
      [
        {
          type   = "metric"
          x      = 12
          y      = 6
          width  = 12
          height = 6
          properties = {
            title  = "Connect - Queue Size"
            region = "ap-southeast-2"
            metrics = [
              ["AWS/Connect", "QueueSize", "InstanceId", var.connect_instance_id]
            ]
            period = 60
            stat   = "Maximum"
            view   = "timeSeries"
          }
        },
        {
          type   = "metric"
          x      = 0
          y      = 12
          width  = 12
          height = 6
          properties = {
            title  = "Connect - Longest Queue Wait Time"
            region = "ap-southeast-2"
            metrics = [
              ["AWS/Connect", "LongestQueueWaitTime", "InstanceId", var.connect_instance_id]
            ]
            period = 60
            stat   = "Maximum"
            view   = "timeSeries"
          }
        },
      ],

      # ── Lambda Metrics (per function) ────────────────────────────────────
      [
        for idx, fn in var.lambda_function_names : {
          type   = "metric"
          x      = (idx % 2) * 12
          y      = 18 + (floor(idx / 2) * 6)
          width  = 12
          height = 6
          properties = {
            title  = "Lambda - ${fn}"
            region = "ap-southeast-2"
            metrics = [
              ["AWS/Lambda", "Invocations", "FunctionName", fn],
              ["AWS/Lambda", "Errors", "FunctionName", fn],
              ["AWS/Lambda", "Duration", "FunctionName", fn],
            ]
            period = 60
            stat   = "Sum"
            view   = "timeSeries"
          }
        }
      ],

      # ── DynamoDB Metrics (per table) ─────────────────────────────────────
      [
        for idx, table in var.dynamodb_table_names : {
          type   = "metric"
          x      = (idx % 2) * 12
          y      = 18 + (ceil(length(var.lambda_function_names) / 2) * 6) + (floor(idx / 2) * 6)
          width  = 12
          height = 6
          properties = {
            title  = "DynamoDB - ${table}"
            region = "ap-southeast-2"
            metrics = [
              ["AWS/DynamoDB", "ConsumedReadCapacityUnits", "TableName", table],
              ["AWS/DynamoDB", "ConsumedWriteCapacityUnits", "TableName", table],
            ]
            period = 60
            stat   = "Sum"
            view   = "timeSeries"
          }
        }
      ],
    )
  })

  tags = var.tags
}
