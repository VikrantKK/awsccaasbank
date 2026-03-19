################################################################################
# VPC Endpoints — Westpac CCaaS Networking Module
# Keep AWS API traffic on the AWS backbone (no internet traversal).
# Supports APRA CPS 234 data-in-transit controls.
################################################################################

data "aws_region" "current" {}

################################################################################
# Gateway Endpoints (no cost, route-table based)
################################################################################

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${data.aws_region.current.id}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = aws_route_table.private[*].id

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-vpce-s3"
  })
}

resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${data.aws_region.current.id}.dynamodb"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = aws_route_table.private[*].id

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-vpce-dynamodb"
  })
}

################################################################################
# Interface Endpoints (ENI-based, private DNS enabled)
################################################################################

locals {
  interface_endpoints = {
    kms     = "com.amazonaws.${data.aws_region.current.id}.kms"
    logs    = "com.amazonaws.${data.aws_region.current.id}.logs"
    sts     = "com.amazonaws.${data.aws_region.current.id}.sts"
    voiceid = "com.amazonaws.${data.aws_region.current.id}.voiceid"
    kinesis = "com.amazonaws.${data.aws_region.current.id}.kinesis-streams"
  }
}

resource "aws_vpc_endpoint" "interface" {
  for_each = local.interface_endpoints

  vpc_id              = aws_vpc.this.id
  service_name        = each.value
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoint.id]

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-vpce-${each.key}"
  })
}
