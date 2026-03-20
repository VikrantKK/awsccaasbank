###############################################################################
# Outputs — Awsccaasbank CCaaS Routing Module
###############################################################################

output "queue_ids" {
  description = "Map of queue keys to their Connect queue IDs"
  value       = { for k, v in aws_connect_queue.this : k => v.queue_id }
}

output "queue_arns" {
  description = "Map of queue keys to their ARNs"
  value       = { for k, v in aws_connect_queue.this : k => v.arn }
}

output "routing_profile_ids" {
  description = "Map of routing profile keys to their IDs"
  value       = { for k, v in aws_connect_routing_profile.this : k => v.routing_profile_id }
}

output "hours_of_operation_ids" {
  description = "Map of hours-of-operation schedule names to their IDs"
  value = {
    standard_hours   = aws_connect_hours_of_operation.standard_hours.hours_of_operation_id
    extended_hours   = aws_connect_hours_of_operation.extended_hours.hours_of_operation_id
    twentyfour_seven = aws_connect_hours_of_operation.twentyfour_seven.hours_of_operation_id
  }
}
