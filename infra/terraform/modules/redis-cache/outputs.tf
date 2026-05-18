output "enabled" {
  description = "Whether cache resources are enabled for this module instance."
  value       = var.enabled
}

output "subnet_group_name" {
  description = "Name of the private ElastiCache subnet group when enabled, otherwise null."
  value       = try(aws_elasticache_subnet_group.this[0].name, null)
}

output "replication_group_id" {
  description = "ElastiCache replication group ID when enabled, otherwise null."
  value       = try(aws_elasticache_replication_group.this[0].id, null)
}

output "replication_group_arn" {
  description = "ElastiCache replication group ARN when enabled, otherwise null."
  value       = try(aws_elasticache_replication_group.this[0].arn, null)
}

output "primary_endpoint_address" {
  description = "Primary endpoint address for the cache when enabled. This is not a credential."
  value       = try(aws_elasticache_replication_group.this[0].primary_endpoint_address, null)
}

output "reader_endpoint_address" {
  description = "Reader endpoint address for replicas when enabled and supported, otherwise null. This is not a credential."
  value       = try(aws_elasticache_replication_group.this[0].reader_endpoint_address, null)
}

output "configuration_endpoint_address" {
  description = "Configuration endpoint for cluster-mode caches when available; null for this cluster-mode-disabled pattern."
  value       = try(aws_elasticache_replication_group.this[0].configuration_endpoint_address, null)
}

output "port" {
  description = "Cache listener port exposed inside the private network."
  value       = var.enabled ? var.port : null
}

output "engine" {
  description = "Configured cache engine."
  value       = var.engine
}

output "engine_version_requested" {
  description = "Requested cache engine version."
  value       = var.engine_version
}

output "engine_version_actual" {
  description = "Actual cache engine version reported by ElastiCache after provisioning when enabled, otherwise null."
  value       = try(aws_elasticache_replication_group.this[0].engine_version_actual, null)
}

output "availability_summary" {
  description = "Review-friendly summary of cache node count and availability settings."
  value = {
    enabled                    = var.enabled
    node_type                  = var.node_type
    primary_nodes              = var.enabled ? 1 : 0
    replica_count              = var.enabled ? var.replica_count : 0
    total_cache_nodes          = var.enabled ? local.cache_node_count : 0
    automatic_failover_enabled = var.enabled ? var.automatic_failover_enabled : false
    multi_az_enabled           = var.enabled ? var.multi_az_enabled : false
  }
}

output "security_summary" {
  description = "Review-friendly summary of private cache security settings."
  value = {
    enabled                    = var.enabled
    private_subnet_group       = var.enabled
    security_group_count       = var.enabled ? length(var.security_group_ids) : 0
    port                       = var.enabled ? var.port : null
    at_rest_encryption_enabled = var.enabled ? var.at_rest_encryption_enabled : null
    transit_encryption_enabled = var.enabled ? var.transit_encryption_enabled : null
    kms_key_supplied           = var.kms_key_id != null
    auth_token_managed_here    = false
  }
}

output "snapshot_summary" {
  description = "Review-friendly summary of cache snapshot and maintenance settings."
  value = {
    enabled                    = var.enabled
    snapshot_retention_days    = var.enabled ? var.snapshot_retention_days : 0
    snapshot_window            = var.enabled ? var.snapshot_window : null
    final_snapshot_identifier  = var.enabled ? var.final_snapshot_identifier : null
    maintenance_window         = var.enabled ? var.maintenance_window : null
    apply_immediately          = var.enabled ? var.apply_immediately : false
    auto_minor_version_upgrade = var.enabled ? var.auto_minor_version_upgrade : false
  }
}

output "connection_reference_summary" {
  description = "Review-friendly connection-reference pattern. Endpoints are not credentials and no auth token value is managed here."
  value       = local.connection_reference_summary
}
