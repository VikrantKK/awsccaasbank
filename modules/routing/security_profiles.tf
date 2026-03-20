###############################################################################
# Security Profiles — Awsccaasbank CCaaS
###############################################################################

# -----------------------------------------------------------------------------
# Supervisor — view metrics, manage queues, listen to recordings
# -----------------------------------------------------------------------------
resource "aws_connect_security_profile" "supervisor" {
  instance_id = var.connect_instance_id
  name        = "${var.project_name}-${var.environment}-supervisor"
  description = "Supervisor security profile with metrics, queue management, and recording access"

  permissions = [
    "AccessMetrics",
    "AgentGrouping.View",
    "BasicAgentAccess",
    "ContactSearch.View",
    "Dashboard.Access",
    "HoursOfOperation.View",
    "ListenCallRecordings",
    "MetricsAgentActivity.Access",
    "MetricsDashboard.Access",
    "QueueMetrics.Access",
    "Queues.View",
    "Queues.Edit",
    "Queues.EnableAndDisable",
    "RealTimeMetrics.Access",
    "HistoricalMetrics.Access",
    "RoutingProfiles.View",
    "SecurityProfiles.View",
    "Users.View",
  ]

  tags = merge(var.tags, {
    SecurityProfile = "supervisor"
  })
}

# -----------------------------------------------------------------------------
# Agent — basic agent permissions
# -----------------------------------------------------------------------------
resource "aws_connect_security_profile" "agent" {
  instance_id = var.connect_instance_id
  name        = "${var.project_name}-${var.environment}-agent"
  description = "Agent security profile with basic contact handling permissions"

  permissions = [
    "BasicAgentAccess",
    "ContactSearch.View",
    "OutboundCallAccess",
    "TransferContact",
  ]

  tags = merge(var.tags, {
    SecurityProfile = "agent"
  })
}
