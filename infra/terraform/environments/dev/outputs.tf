output "environment_name" {
  description = "Environment represented by this Terraform root."
  value       = local.environment
}

output "aws_region" {
  description = "AWS region configured for this environment root."
  value       = var.aws_region
}

output "name_prefix" {
  description = "Public-safe naming prefix for future resources."
  value       = local.name_prefix
}

output "common_tags" {
  description = "Common public-safe tags passed to future modules."
  value       = local.common_tags
}

output "network_defaults" {
  description = "Network inputs passed to the network module."
  value       = local.network_defaults
}

output "vpc_id" {
  description = "ID of the environment VPC."
  value       = module.network.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block assigned to the environment VPC."
  value       = module.network.vpc_cidr_block
}

output "public_subnet_ids" {
  description = "Public subnet IDs for future load balancer resources."
  value       = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs for future ECS, database, and cache resources."
  value       = module.network.private_subnet_ids
}

output "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets."
  value       = module.network.public_subnet_cidrs
}

output "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets."
  value       = module.network.private_subnet_cidrs
}

output "public_route_table_id" {
  description = "Public route table ID for the environment VPC."
  value       = module.network.public_route_table_id
}

output "private_route_table_ids" {
  description = "Private route table IDs for the environment VPC."
  value       = module.network.private_route_table_ids
}

output "internet_gateway_id" {
  description = "Internet gateway ID for the environment VPC."
  value       = module.network.internet_gateway_id
}

output "nat_gateway_enabled" {
  description = "Whether the environment is configured to create a NAT gateway."
  value       = module.network.nat_gateway_enabled
}

output "nat_gateway_id" {
  description = "NAT gateway ID when enabled, otherwise null."
  value       = module.network.nat_gateway_id
}

output "security_group_defaults" {
  description = "Security group boundary inputs passed to the security-groups module."
  value       = local.security_group_defaults
}

output "load_balancer_security_group_id" {
  description = "Security group ID for the future public Application Load Balancer."
  value       = module.security_groups.load_balancer_security_group_id
}

output "ecs_service_security_group_id" {
  description = "Security group ID for future private ECS services."
  value       = module.security_groups.ecs_service_security_group_id
}

output "rds_postgres_security_group_id" {
  description = "Security group ID for future private PostgreSQL/RDS resources."
  value       = module.security_groups.rds_postgres_security_group_id
}

output "redis_cache_security_group_id" {
  description = "Security group ID for future private Redis/ElastiCache resources when enabled; null otherwise."
  value       = module.security_groups.redis_cache_security_group_id
}

output "security_group_rule_summary" {
  description = "Review-friendly summary of security group traffic boundaries."
  value       = module.security_groups.rule_summary
}

output "iam_defaults" {
  description = "IAM secret-reference inputs passed to the IAM module. These are references only, not secret values."
  value       = local.iam_defaults
}

output "ecs_task_execution_role_name" {
  description = "Name of the ECS task execution role."
  value       = module.iam.ecs_task_execution_role_name
}

output "ecs_task_execution_role_arn" {
  description = "ARN of the ECS task execution role for future ECS task definitions."
  value       = module.iam.ecs_task_execution_role_arn
}

output "ecs_task_role_name" {
  description = "Name of the ECS application task role."
  value       = module.iam.ecs_task_role_name
}

output "ecs_task_role_arn" {
  description = "ARN of the ECS application task role for future ECS task definitions."
  value       = module.iam.ecs_task_role_arn
}

output "secret_reference_policy_summary" {
  description = "Review-friendly summary of IAM secret-reference policies."
  value       = module.iam.secret_reference_policy_summary
}

output "platform_defaults" {
  description = "Cost and availability defaults that future modules will consume."
  value       = local.platform_defaults
}

output "planned_module_contract" {
  description = "Planned module set shared by dev and prod; module calls are added ticket-by-ticket."
  value       = local.planned_module_contract
}
