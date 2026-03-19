###############################################################################
# Amazon Connect Queues & Routing Profiles — Westpac CCaaS
###############################################################################

locals {
  hours_of_operation_map = {
    standard_hours   = aws_connect_hours_of_operation.standard_hours.hours_of_operation_id
    extended_hours   = aws_connect_hours_of_operation.extended_hours.hours_of_operation_id
    twentyfour_seven = aws_connect_hours_of_operation.twentyfour_seven.hours_of_operation_id
  }
}

# -----------------------------------------------------------------------------
# Queues
# -----------------------------------------------------------------------------
resource "aws_connect_queue" "this" {
  for_each = var.queues

  instance_id           = var.connect_instance_id
  name                  = "${var.project_name}-${var.environment}-${replace(each.key, "_", "-")}"
  description           = each.value.description
  hours_of_operation_id = local.hours_of_operation_map[each.value.hours_type]
  max_contacts          = each.value.max_contacts

  tags = merge(var.tags, {
    Queue = each.key
  })
}

# -----------------------------------------------------------------------------
# Routing Profiles
# -----------------------------------------------------------------------------
resource "aws_connect_routing_profile" "this" {
  for_each = var.routing_profiles

  instance_id            = var.connect_instance_id
  name                   = "${var.project_name}-${var.environment}-${replace(each.key, "_", "-")}"
  description            = each.value.description
  default_outbound_queue_id = aws_connect_queue.this[keys(each.value.queue_priorities)[0]].queue_id

  media_concurrencies {
    channel     = "VOICE"
    concurrency = 1
  }

  media_concurrencies {
    channel     = "CHAT"
    concurrency = 3
  }

  dynamic "queue_configs" {
    for_each = each.value.queue_priorities
    content {
      channel  = "VOICE"
      delay    = queue_configs.value.delay
      priority = queue_configs.value.priority
      queue_id = aws_connect_queue.this[queue_configs.key].queue_id
    }
  }

  dynamic "queue_configs" {
    for_each = each.value.queue_priorities
    content {
      channel  = "CHAT"
      delay    = queue_configs.value.delay
      priority = queue_configs.value.priority
      queue_id = aws_connect_queue.this[queue_configs.key].queue_id
    }
  }

  tags = merge(var.tags, {
    RoutingProfile = each.key
  })
}
