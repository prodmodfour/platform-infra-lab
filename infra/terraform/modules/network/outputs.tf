output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.this.id
}

output "vpc_cidr_block" {
  description = "CIDR block assigned to the VPC."
  value       = aws_vpc.this.cidr_block
}

output "public_subnet_ids" {
  description = "IDs of public subnets, ordered by input CIDR order."
  value       = [for key in sort(keys(aws_subnet.public)) : aws_subnet.public[key].id]
}

output "private_subnet_ids" {
  description = "IDs of private subnets, ordered by input CIDR order."
  value       = [for key in sort(keys(aws_subnet.private)) : aws_subnet.private[key].id]
}

output "public_subnet_cidrs" {
  description = "CIDR blocks for the public subnets."
  value       = var.public_subnet_cidrs
}

output "private_subnet_cidrs" {
  description = "CIDR blocks for the private subnets."
  value       = var.private_subnet_cidrs
}

output "internet_gateway_id" {
  description = "ID of the internet gateway attached to the VPC."
  value       = aws_internet_gateway.this.id
}

output "public_route_table_id" {
  description = "ID of the shared public route table."
  value       = aws_route_table.public.id
}

output "private_route_table_ids" {
  description = "IDs of private route tables, ordered by input CIDR order."
  value       = [for key in sort(keys(aws_route_table.private)) : aws_route_table.private[key].id]
}

output "nat_gateway_enabled" {
  description = "Whether this module is configured to create a NAT gateway."
  value       = var.enable_nat_gateway
}

output "nat_gateway_id" {
  description = "ID of the NAT gateway when enabled, otherwise null."
  value       = try(aws_nat_gateway.this[0].id, null)
}
