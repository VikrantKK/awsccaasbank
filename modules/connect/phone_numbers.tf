###############################################################################
# Phone Numbers — provisioned via for_each from var.phone_numbers
###############################################################################

resource "aws_connect_phone_number" "this" {
  for_each = var.phone_numbers

  target_arn   = aws_connect_instance.this.arn
  country_code = each.value.country_code
  type         = each.value.type

  tags = merge(var.tags, {
    Name = each.key
  })
}
