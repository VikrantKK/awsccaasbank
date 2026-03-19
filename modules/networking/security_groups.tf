################################################################################
# Security Groups — Westpac CCaaS Networking Module
################################################################################

# Lambda Security Group — allows all outbound for CRM API calls, no inbound
resource "aws_security_group" "lambda" {
  name        = "${var.project_name}-${var.environment}-lambda-sg"
  description = "Security group for Lambda functions — egress only, no inbound"
  vpc_id      = aws_vpc.this.id

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-lambda-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_egress_rule" "lambda_all_outbound" {
  security_group_id = aws_security_group.lambda.id
  description       = "Allow all outbound traffic for CRM API and AWS service calls"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-lambda-egress-all"
  })
}

# VPC Endpoint Security Group — allows inbound HTTPS from VPC CIDR
resource "aws_security_group" "vpc_endpoint" {
  name        = "${var.project_name}-${var.environment}-vpce-sg"
  description = "Security group for VPC interface endpoints — HTTPS from VPC"
  vpc_id      = aws_vpc.this.id

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-vpce-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "vpce_https" {
  security_group_id = aws_security_group.vpc_endpoint.id
  description       = "Allow HTTPS inbound from VPC CIDR for interface endpoints"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = var.vpc_cidr

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-vpce-ingress-https"
  })
}
