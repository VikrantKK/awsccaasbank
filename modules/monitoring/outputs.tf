################################################################################
# Outputs — Monitoring Module
################################################################################

output "dashboard_arn" {
  description = "ARN of the CCaaS CloudWatch dashboard"
  value       = aws_cloudwatch_dashboard.ccaas.dashboard_arn
}

output "warning_sns_topic_arn" {
  description = "ARN of the warning-level SNS topic"
  value       = aws_sns_topic.warning.arn
}

output "critical_sns_topic_arn" {
  description = "ARN of the critical-level SNS topic"
  value       = aws_sns_topic.critical.arn
}

output "connect_log_group_name" {
  description = "Name of the Amazon Connect CloudWatch Log Group"
  value       = aws_cloudwatch_log_group.connect.name
}
