output "connect_instance_id" {
  description = "Amazon Connect instance ID"
  value       = module.connect.instance_id
}

output "connect_instance_arn" {
  description = "Amazon Connect instance ARN"
  value       = module.connect.instance_arn
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.networking.vpc_id
}

output "recordings_bucket_arn" {
  description = "S3 bucket ARN for call recordings"
  value       = module.storage.recordings_bucket_arn
}

output "lambda_function_arns" {
  description = "Map of Lambda function ARNs"
  value = {
    cti_adapter      = module.lambda.cti_adapter_function_arn
    crm_lookup       = module.lambda.crm_lookup_function_arn
    post_call_survey = module.lambda.post_call_survey_function_arn
  }
}

output "queue_ids" {
  description = "Map of Connect queue IDs"
  value       = module.routing.queue_ids
}

output "monitoring_dashboard_arn" {
  description = "CloudWatch dashboard ARN"
  value       = module.monitoring.dashboard_arn
}

output "warning_sns_topic_arn" {
  description = "SNS topic ARN for warning alerts"
  value       = module.monitoring.warning_sns_topic_arn
}

output "critical_sns_topic_arn" {
  description = "SNS topic ARN for critical alerts"
  value       = module.monitoring.critical_sns_topic_arn
}
