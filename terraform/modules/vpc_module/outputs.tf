output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.main.id
}

output "vpc_arn" {
  description = "ARN of the VPC."
  value       = aws_vpc.main.arn
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC."
  value       = aws_vpc.main.cidr_block
}

output "azs" {
  description = "Availability zones used by the subnets."
  value       = local.azs
}

output "public_subnet_ids" {
  description = "IDs of the public subnets."
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets."
  value       = aws_subnet.private[*].id
}

output "internet_gateway_id" {
  description = "ID of the internet gateway (null if no public subnets)."
  value       = try(aws_internet_gateway.main[0].id, null)
}

output "nat_gateway_ids" {
  description = "IDs of the NAT gateways."
  value       = aws_nat_gateway.main[*].id
}

output "nat_public_ips" {
  description = "Public Elastic IPs of the NAT gateways (useful for allow-listing outbound traffic)."
  value       = aws_eip.nat[*].public_ip
}

output "public_route_table_id" {
  description = "ID of the public route table (null if no public subnets)."
  value       = try(aws_route_table.public[0].id, null)
}

output "private_route_table_ids" {
  description = "IDs of the private route tables."
  value       = aws_route_table.private[*].id
}

output "default_security_group_id" {
  description = "ID of the VPC's default security group."
  value       = aws_vpc.main.default_security_group_id
}
