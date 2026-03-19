###############################################################################
# Lambda Function Associations
###############################################################################

resource "aws_connect_lambda_function_association" "this" {
  for_each = toset(var.lambda_function_arns)

  instance_id  = aws_connect_instance.this.id
  function_arn = each.value
}
