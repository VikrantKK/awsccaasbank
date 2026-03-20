###############################################################################
# Hours of Operation — Awsccaasbank CCaaS (Australia/Sydney)
###############################################################################

locals {
  weekdays = ["MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY"]
  all_days = ["MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY", "SATURDAY", "SUNDAY"]
}

# -----------------------------------------------------------------------------
# Standard Hours: Mon–Fri 08:00–18:00 AEST/AEDT
# -----------------------------------------------------------------------------
resource "aws_connect_hours_of_operation" "standard_hours" {
  instance_id = var.connect_instance_id
  name        = "${var.project_name}-${var.environment}-standard-hours"
  description = "Standard business hours Mon-Fri 08:00-18:00 AEST/AEDT"
  time_zone   = "Australia/Sydney"

  dynamic "config" {
    for_each = toset(local.weekdays)
    content {
      day = config.value

      start_time {
        hours   = 8
        minutes = 0
      }

      end_time {
        hours   = 18
        minutes = 0
      }
    }
  }

  tags = var.tags
}

# -----------------------------------------------------------------------------
# Extended Hours: Mon–Fri 07:00–21:00, Sat 09:00–17:00 AEST/AEDT
# -----------------------------------------------------------------------------
resource "aws_connect_hours_of_operation" "extended_hours" {
  instance_id = var.connect_instance_id
  name        = "${var.project_name}-${var.environment}-extended-hours"
  description = "Extended business hours Mon-Fri 07:00-21:00, Sat 09:00-17:00 AEST/AEDT"
  time_zone   = "Australia/Sydney"

  dynamic "config" {
    for_each = toset(local.weekdays)
    content {
      day = config.value

      start_time {
        hours   = 7
        minutes = 0
      }

      end_time {
        hours   = 21
        minutes = 0
      }
    }
  }

  config {
    day = "SATURDAY"

    start_time {
      hours   = 9
      minutes = 0
    }

    end_time {
      hours   = 17
      minutes = 0
    }
  }

  tags = var.tags
}

# -----------------------------------------------------------------------------
# 24/7 Hours: All days 00:00–23:59 AEST/AEDT
# -----------------------------------------------------------------------------
resource "aws_connect_hours_of_operation" "twentyfour_seven" {
  instance_id = var.connect_instance_id
  name        = "${var.project_name}-${var.environment}-24x7-hours"
  description = "24/7 hours of operation"
  time_zone   = "Australia/Sydney"

  dynamic "config" {
    for_each = toset(local.all_days)
    content {
      day = config.value

      start_time {
        hours   = 0
        minutes = 0
      }

      end_time {
        hours   = 23
        minutes = 59
      }
    }
  }

  tags = var.tags
}
