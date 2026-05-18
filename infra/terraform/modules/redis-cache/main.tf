locals {
  component_tags = merge(var.common_tags, {
    Environment = var.environment
    Component   = "redis-cache"
  })

  replication_group_id = "${var.name_prefix}-redis"
  subnet_group_name    = "${var.name_prefix}-redis-subnets"
  cache_node_count     = var.replica_count + 1

  connection_reference_summary = {
    endpoint_values_are_credentials = false
    secret_value_in_terraform       = false
    auth_token_managed_here         = false
    auth_token_note                 = "No Redis AUTH token is stored in this public module; production should manage cache auth/ACL material through a secure secret workflow."
  }
}

resource "aws_elasticache_subnet_group" "this" {
  count = var.enabled ? 1 : 0

  name        = local.subnet_group_name
  description = "Private subnet group for the Redis/Valkey cache"
  subnet_ids  = var.private_subnet_ids

  tags = merge(local.component_tags, {
    Name = local.subnet_group_name
    Tier = "private-cache"
  })
}

resource "aws_elasticache_replication_group" "this" {
  count = var.enabled ? 1 : 0

  replication_group_id = local.replication_group_id
  description          = "Private ${var.engine} cache for ${var.environment}"

  engine               = var.engine
  engine_version       = var.engine_version
  node_type            = var.node_type
  num_cache_clusters   = local.cache_node_count
  parameter_group_name = var.parameter_group_name
  port                 = var.port

  subnet_group_name  = aws_elasticache_subnet_group.this[0].name
  security_group_ids = var.security_group_ids

  automatic_failover_enabled = var.automatic_failover_enabled
  multi_az_enabled           = var.multi_az_enabled

  at_rest_encryption_enabled = var.at_rest_encryption_enabled
  transit_encryption_enabled = var.transit_encryption_enabled
  kms_key_id                 = var.kms_key_id

  snapshot_retention_limit   = var.snapshot_retention_days
  snapshot_window            = var.snapshot_window
  final_snapshot_identifier  = var.final_snapshot_identifier
  maintenance_window         = var.maintenance_window
  apply_immediately          = var.apply_immediately
  auto_minor_version_upgrade = var.auto_minor_version_upgrade

  tags = merge(local.component_tags, {
    Name = local.replication_group_id
    Tier = "private-cache"
  })

  lifecycle {
    precondition {
      condition     = length(local.replication_group_id) <= 40
      error_message = "ElastiCache replication group IDs must be 40 characters or fewer; shorten name_prefix."
    }

    precondition {
      condition     = var.enabled ? length(var.security_group_ids) > 0 : true
      error_message = "security_group_ids must include the private Redis cache security group when the cache is enabled."
    }

    precondition {
      condition     = (var.automatic_failover_enabled || var.multi_az_enabled) ? var.replica_count >= 1 : true
      error_message = "replica_count must be at least 1 when automatic failover or Multi-AZ is enabled."
    }

    precondition {
      condition     = var.kms_key_id == null ? true : var.at_rest_encryption_enabled
      error_message = "kms_key_id should only be supplied when at_rest_encryption_enabled is true."
    }
  }
}
