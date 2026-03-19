###############################################################################
# Lex V2 Bot Association
###############################################################################

resource "aws_connect_bot_association" "this" {
  count = var.lex_bot_alias_arn != "" ? 1 : 0

  instance_id = aws_connect_instance.this.id

  lex_bot {
    lex_region = var.aws_region
    name       = var.lex_bot_alias_arn
  }
}
