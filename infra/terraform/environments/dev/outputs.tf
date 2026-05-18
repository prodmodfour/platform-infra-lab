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
  description = "Public subnet IDs for load balancer resources."
  value       = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs for ECS, database, and cache resources."
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
  description = "Security group ID for the public Application Load Balancer."
  value       = module.security_groups.load_balancer_security_group_id
}

output "ecs_service_security_group_id" {
  description = "Security group ID for private ECS services."
  value       = module.security_groups.ecs_service_security_group_id
}

output "rds_postgres_security_group_id" {
  description = "Security group ID for private PostgreSQL/RDS resources."
  value       = module.security_groups.rds_postgres_security_group_id
}

output "redis_cache_security_group_id" {
  description = "Security group ID for optional private Redis/ElastiCache resources when enabled; null otherwise."
  value       = module.security_groups.redis_cache_security_group_id
}

output "security_group_rule_summary" {
  description = "Review-friendly summary of security group traffic boundaries."
  value       = module.security_groups.rule_summary
}

output "redis_cache_defaults" {
  description = "Review-friendly Redis/Valkey cache defaults for this environment."
  value       = local.redis_cache_defaults
}

output "redis_cache_enabled" {
  description = "Whether the optional Redis/Valkey cache resources are enabled."
  value       = module.redis_cache.enabled
}

output "redis_cache_subnet_group_name" {
  description = "Private ElastiCache subnet group name when Redis is enabled, otherwise null."
  value       = module.redis_cache.subnet_group_name
}

output "redis_cache_replication_group_id" {
  description = "ElastiCache replication group ID when Redis is enabled, otherwise null."
  value       = module.redis_cache.replication_group_id
}

output "redis_cache_replication_group_arn" {
  description = "ElastiCache replication group ARN when Redis is enabled, otherwise null."
  value       = module.redis_cache.replication_group_arn
}

output "redis_cache_primary_endpoint_address" {
  description = "Private cache primary endpoint when Redis is enabled. This is not a credential."
  value       = module.redis_cache.primary_endpoint_address
}

output "redis_cache_reader_endpoint_address" {
  description = "Private cache reader endpoint when replicas are present, otherwise null. This is not a credential."
  value       = module.redis_cache.reader_endpoint_address
}

output "redis_cache_port" {
  description = "Redis/Valkey port exposed inside private subnets when enabled, otherwise null."
  value       = module.redis_cache.port
}

output "redis_cache_availability_summary" {
  description = "Review-friendly summary of Redis/Valkey cache node count and availability settings."
  value       = module.redis_cache.availability_summary
}

output "redis_cache_security_summary" {
  description = "Review-friendly summary of Redis/Valkey private security settings."
  value       = module.redis_cache.security_summary
}

output "redis_cache_snapshot_summary" {
  description = "Review-friendly summary of Redis/Valkey snapshot and maintenance settings."
  value       = module.redis_cache.snapshot_summary
}

output "redis_cache_connection_reference_summary" {
  description = "Review-friendly Redis/Valkey connection-reference pattern; no cache auth token value is exposed."
  value       = module.redis_cache.connection_reference_summary
}

output "rds_postgres_defaults" {
  description = "Review-friendly PostgreSQL/RDS defaults for this environment."
  value       = local.rds_postgres_defaults
}

output "rds_postgres_subnet_group_name" {
  description = "Private DB subnet group name used by PostgreSQL/RDS."
  value       = module.rds_postgres.db_subnet_group_name
}

output "rds_postgres_instance_identifier" {
  description = "RDS PostgreSQL instance identifier."
  value       = module.rds_postgres.db_instance_identifier
}

output "rds_postgres_instance_arn" {
  description = "RDS PostgreSQL instance ARN."
  value       = module.rds_postgres.db_instance_arn
}

output "rds_postgres_resource_id" {
  description = "Stable RDS resource ID used by monitoring integrations."
  value       = module.rds_postgres.db_instance_resource_id
}

output "rds_postgres_endpoint" {
  description = "Private RDS PostgreSQL endpoint including port. This is not a credential."
  value       = module.rds_postgres.endpoint
}

output "rds_postgres_address" {
  description = "Private RDS PostgreSQL hostname/address. This is not a credential."
  value       = module.rds_postgres.address
}

output "rds_postgres_port" {
  description = "PostgreSQL port exposed inside private subnets."
  value       = module.rds_postgres.port
}

output "rds_postgres_database_name" {
  description = "Initial PostgreSQL database name."
  value       = module.rds_postgres.database_name
}

output "rds_postgres_master_user_secret_arn" {
  description = "Secrets Manager ARN for the RDS-managed master user secret. This is a reference, not a secret value."
  value       = module.rds_postgres.master_user_secret_arn
}

output "rds_postgres_credential_reference_summary" {
  description = "Review-friendly RDS credential-reference pattern; no secret values are exposed."
  value       = module.rds_postgres.credential_reference_summary
}

output "rds_postgres_publicly_accessible" {
  description = "Whether the RDS instance is publicly accessible; expected to be false."
  value       = module.rds_postgres.publicly_accessible
}

output "rds_postgres_backup_summary" {
  description = "Review-friendly summary of RDS backup and deletion-protection settings."
  value       = module.rds_postgres.backup_summary
}

output "rds_postgres_storage_summary" {
  description = "Review-friendly summary of RDS storage and availability settings."
  value       = module.rds_postgres.storage_summary
}

output "rds_postgres_monitoring_summary" {
  description = "Review-friendly summary of RDS log export and monitoring settings."
  value       = module.rds_postgres.monitoring_summary
}

output "load_balancer_defaults" {
  description = "Review-friendly load balancer defaults for this environment."
  value       = local.load_balancer_defaults
}

output "load_balancer_name" {
  description = "Name of the public Application Load Balancer."
  value       = module.load_balancer.load_balancer_name
}

output "load_balancer_arn" {
  description = "ARN of the public Application Load Balancer."
  value       = module.load_balancer.load_balancer_arn
}

output "load_balancer_arn_suffix" {
  description = "ARN suffix of the public Application Load Balancer used by CloudWatch metrics."
  value       = module.load_balancer.load_balancer_arn_suffix
}

output "load_balancer_dns_name" {
  description = "DNS name assigned to the public Application Load Balancer."
  value       = module.load_balancer.load_balancer_dns_name
}

output "load_balancer_zone_id" {
  description = "Canonical hosted zone ID for ALB DNS aliases."
  value       = module.load_balancer.load_balancer_zone_id
}

output "load_balancer_http_listener_arn" {
  description = "HTTP listener ARN used by ECS service listener rules."
  value       = module.load_balancer.http_listener_arn
}

output "load_balancer_https_listener_arn" {
  description = "HTTPS listener ARN when enabled, otherwise null."
  value       = module.load_balancer.https_listener_arn
}

output "load_balancer_listener_summary" {
  description = "Review-friendly summary of ALB listeners."
  value       = module.load_balancer.listener_summary
}

output "load_balancer_target_group_wiring_pattern" {
  description = "Summary of how ECS service target groups connect to the ALB."
  value       = module.load_balancer.target_group_wiring_pattern
}

output "secrets_manager_reference_defaults" {
  description = "Review-friendly defaults for metadata-only Secrets Manager reference containers."
  value       = local.secrets_manager_reference_defaults
}

output "secrets_manager_ecs_secret_names_by_service" {
  description = "Secrets Manager secret names created for ECS secret injection, keyed by service and environment variable. Names are not values."
  value       = module.secrets_manager_references.ecs_secret_names_by_service
}

output "secrets_manager_ecs_secret_arns" {
  description = "Secrets Manager ARNs created for ECS secret injection. These are references only, not secret values."
  value       = module.secrets_manager_references.ecs_execution_secret_arns
}

output "secrets_manager_metadata_summary" {
  description = "Review-friendly summary of Secrets Manager metadata-only resources."
  value       = module.secrets_manager_references.secret_metadata_summary
}

output "secrets_manager_value_management_summary" {
  description = "Summary of how secret values stay outside this public Terraform repository."
  value       = module.secrets_manager_references.value_management_summary
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

output "ecs_service_defaults" {
  description = "Review-friendly summary of ECS service module wiring."
  value       = local.ecs_service_defaults
}

output "ecs_cluster_name" {
  description = "Name of the shared ECS cluster for private Fargate services."
  value       = aws_ecs_cluster.platform.name
}

output "ecs_cluster_arn" {
  description = "ARN of the shared ECS cluster for private Fargate services."
  value       = aws_ecs_cluster.platform.arn
}

output "ecs_service_summaries" {
  description = "Review-friendly ECS service summaries keyed by service name. Secret references are names only in module summaries."
  value       = { for service_name, service in module.ecs_services : service_name => service.service_summary }
}

output "ecs_service_target_group_arns" {
  description = "ALB target group ARNs created for each ECS service."
  value       = { for service_name, service in module.ecs_services : service_name => service.target_group_arn }
}

output "ecs_service_target_group_arn_suffixes" {
  description = "ALB target group ARN suffixes used by CloudWatch ApplicationELB target health metrics."
  value       = { for service_name, service in module.ecs_services : service_name => service.target_group_arn_suffix }
}

output "ecs_service_log_group_names" {
  description = "CloudWatch log group names created for each ECS service."
  value       = { for service_name, service in module.ecs_services : service_name => service.log_group_name }
}

output "observability_defaults" {
  description = "Review-friendly CloudWatch dashboard and alarm defaults for this environment."
  value       = local.observability_defaults
}

output "cloudwatch_dashboard_name" {
  description = "CloudWatch dashboard name for this environment."
  value       = module.observability.dashboard_name
}

output "cloudwatch_dashboard_arn" {
  description = "CloudWatch dashboard ARN for this environment."
  value       = module.observability.dashboard_arn
}

output "cloudwatch_log_group_naming_convention" {
  description = "Expected ECS service log group naming convention used by observability dashboard widgets."
  value       = module.observability.log_group_naming_convention
}

output "cloudwatch_alarm_names" {
  description = "CloudWatch alarm names created for ALB, ECS, and RDS signals."
  value       = module.observability.alarm_names
}

output "cloudwatch_alarm_summary" {
  description = "Review-friendly summary of CloudWatch alarm thresholds and action wiring."
  value       = module.observability.alarm_summary
}

output "cloudwatch_dashboard_summary" {
  description = "Review-friendly summary of CloudWatch dashboard coverage."
  value       = module.observability.dashboard_summary
}

output "platform_defaults" {
  description = "Cost and availability defaults that future modules will consume."
  value       = local.platform_defaults
}

output "planned_module_contract" {
  description = "Planned module set shared by dev and prod; module calls are added ticket-by-ticket."
  value       = local.planned_module_contract
}
