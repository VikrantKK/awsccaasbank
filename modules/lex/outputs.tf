output "bot_id" {
  description = "The ID of the Lex V2 self-service bot"
  value       = aws_lexv2models_bot.self_service.id
}

output "bot_arn" {
  description = "The ARN of the Lex V2 self-service bot"
  value       = aws_lexv2models_bot.self_service.arn
}

output "bot_version" {
  description = "The published bot version number"
  value       = aws_lexv2models_bot_version.current.bot_version
}

# Placeholder — bot_alias_arn is not yet available via hashicorp/aws provider.
# Connect bot_association in the connect module uses bot_id + version directly.
output "bot_alias_arn" {
  description = "Placeholder for bot alias ARN (pending provider support)"
  value       = ""
}
