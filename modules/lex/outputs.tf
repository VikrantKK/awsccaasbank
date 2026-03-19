output "bot_id" {
  description = "The ID of the Lex V2 self-service bot"
  value       = aws_lexv2models_bot.self_service.id
}

output "bot_alias_id" {
  description = "The alias ID for the current environment bot alias"
  value       = aws_lexv2models_bot_alias.environment.bot_alias_id
}

output "bot_alias_arn" {
  description = "The ARN of the environment bot alias, used for Amazon Connect integration"
  value       = aws_lexv2models_bot_alias.environment.arn
}
