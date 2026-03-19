###############################################################################
# Outputs — Lambda function ARNs, names, and invoke ARNs
###############################################################################

# --- CTI Adapter ---

output "cti_adapter_function_arn" {
  description = "ARN of the CTI adapter Lambda function"
  value       = aws_lambda_function.this["cti_adapter"].arn
}

output "cti_adapter_function_name" {
  description = "Name of the CTI adapter Lambda function"
  value       = aws_lambda_function.this["cti_adapter"].function_name
}

output "cti_adapter_invoke_arn" {
  description = "Invoke ARN of the CTI adapter Lambda function"
  value       = aws_lambda_function.this["cti_adapter"].invoke_arn
}

# --- CRM Lookup ---

output "crm_lookup_function_arn" {
  description = "ARN of the CRM lookup Lambda function"
  value       = aws_lambda_function.this["crm_lookup"].arn
}

output "crm_lookup_function_name" {
  description = "Name of the CRM lookup Lambda function"
  value       = aws_lambda_function.this["crm_lookup"].function_name
}

output "crm_lookup_invoke_arn" {
  description = "Invoke ARN of the CRM lookup Lambda function"
  value       = aws_lambda_function.this["crm_lookup"].invoke_arn
}

# --- Post-Call Survey ---

output "post_call_survey_function_arn" {
  description = "ARN of the post-call survey Lambda function"
  value       = aws_lambda_function.this["post_call_survey"].arn
}

output "post_call_survey_function_name" {
  description = "Name of the post-call survey Lambda function"
  value       = aws_lambda_function.this["post_call_survey"].function_name
}

output "post_call_survey_invoke_arn" {
  description = "Invoke ARN of the post-call survey Lambda function"
  value       = aws_lambda_function.this["post_call_survey"].invoke_arn
}
