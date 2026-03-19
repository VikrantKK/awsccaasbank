###############################################################################
# Contact Flows — loaded from external JSON definitions
###############################################################################

resource "aws_connect_contact_flow" "inbound_main" {
  instance_id = aws_connect_instance.this.id
  name        = "${var.project_name}-${var.environment}-inbound-main"
  type        = "CONTACT_FLOW"
  content     = file("${var.contact_flows_path}/inbound_main.json")

  tags = var.tags
}

resource "aws_connect_contact_flow" "transfer_to_queue" {
  instance_id = aws_connect_instance.this.id
  name        = "${var.project_name}-${var.environment}-transfer-to-queue"
  type        = "CONTACT_FLOW"
  content     = file("${var.contact_flows_path}/transfer_to_queue.json")

  tags = var.tags
}

resource "aws_connect_contact_flow" "customer_queue_hold" {
  instance_id = aws_connect_instance.this.id
  name        = "${var.project_name}-${var.environment}-customer-queue-hold"
  type        = "CUSTOMER_QUEUE"
  content     = file("${var.contact_flows_path}/customer_queue_hold.json")

  tags = var.tags
}

resource "aws_connect_contact_flow" "disconnect" {
  instance_id = aws_connect_instance.this.id
  name        = "${var.project_name}-${var.environment}-disconnect"
  type        = "CONTACT_FLOW"
  content     = file("${var.contact_flows_path}/disconnect.json")

  tags = var.tags
}
