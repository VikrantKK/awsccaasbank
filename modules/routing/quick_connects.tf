###############################################################################
# Quick Connects — Awsccaasbank CCaaS
###############################################################################

resource "aws_connect_quick_connect" "this" {
  for_each = var.quick_connects

  instance_id = var.connect_instance_id
  name        = "${var.project_name}-${var.environment}-${replace(each.key, "_", "-")}"
  description = "Quick connect for ${replace(each.key, "_", " ")}"

  quick_connect_config {
    quick_connect_type = "QUEUE"

    queue_config {
      queue_id        = aws_connect_queue.this[each.value.queue_key].queue_id
      contact_flow_id = each.value.contact_flow_id
    }
  }

  tags = merge(var.tags, {
    QuickConnect = each.key
  })
}
