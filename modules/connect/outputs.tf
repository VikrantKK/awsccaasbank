output "instance_id" {
  description = "Amazon Connect instance ID"
  value       = aws_connect_instance.this.id
}

output "instance_arn" {
  description = "Amazon Connect instance ARN"
  value       = aws_connect_instance.this.arn
}

output "contact_flow_ids" {
  description = "Map of contact flow logical names to their IDs"
  value = {
    inbound_main        = aws_connect_contact_flow.inbound_main.contact_flow_id
    transfer_to_queue   = aws_connect_contact_flow.transfer_to_queue.contact_flow_id
    customer_queue_hold = aws_connect_contact_flow.customer_queue_hold.contact_flow_id
    disconnect          = aws_connect_contact_flow.disconnect.contact_flow_id
  }
}

output "phone_number_ids" {
  description = "Map of phone number logical names to their IDs"
  value       = { for k, v in aws_connect_phone_number.this : k => v.id }
}

output "ctr_stream_arn" {
  description = "ARN of the Contact Trace Records Kinesis Data Stream"
  value       = aws_kinesis_stream.ctr_stream.arn
}

output "agent_events_stream_arn" {
  description = "ARN of the Agent Events Kinesis Data Stream"
  value       = aws_kinesis_stream.agent_events_stream.arn
}
