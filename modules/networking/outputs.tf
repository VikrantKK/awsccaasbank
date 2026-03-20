################################################################################
# Outputs — Awsccaasbank CCaaS Networking Module
################################################################################

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.this.id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs (Lambda placement)"
  value       = aws_subnet.private[*].id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs (NAT Gateway placement)"
  value       = aws_subnet.public[*].id
}

output "lambda_security_group_id" {
  description = "Security group ID for Lambda functions"
  value       = aws_security_group.lambda.id
}

output "nat_gateway_ips" {
  description = "Elastic IP addresses of the NAT Gateways"
  value       = aws_eip.nat[*].public_ip
}
