###############################################################################
# Lex V2 Bot Association
#
# NOTE: aws_connect_bot_association requires a Lex V1 bot name or a V2 bot
# alias ARN in the lex_bot block. Since aws_lexv2models_bot_alias is not yet
# available in the hashicorp/aws provider, this association is gated on
# var.lex_bot_alias_arn being non-empty. Once bot aliases are manageable via
# Terraform (or created out-of-band), provide the alias ARN to enable this.
###############################################################################

resource "aws_connect_bot_association" "this" {
  count = var.lex_bot_alias_arn != "" ? 1 : 0

  instance_id = aws_connect_instance.this.id

  lex_bot {
    lex_region = var.aws_region
    name       = var.lex_bot_alias_arn
  }
}
