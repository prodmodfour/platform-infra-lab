# Redis cache module

This module models an optional private ElastiCache Redis/Valkey-style cache for the public-safe AWS platform lab.

It is intentionally small and reviewable. It does not make the repository a one-click production cache deployment, and it does not store cache passwords or token values.

## Resources

When `enabled = true`, the module creates:

- `aws_elasticache_subnet_group` across private subnets
- `aws_elasticache_replication_group` for a cluster-mode-disabled Redis/Valkey-style cache

When `enabled = false`, no cache resources are created and outputs return `null` or disabled summaries.

## Optional cache use

The cache tier is optional because not every backend service needs Redis/Valkey.

Example use cases for a real service might include:

- short-lived application cache entries
- rate-limit counters
- idempotency keys
- background job coordination
- session or tenant metadata caches, if the application design allows it

This module should not be used as the system of record. PostgreSQL/RDS remains the durable data store pattern in this lab.

## Private access

The module expects:

- private subnet IDs from the network module
- the Redis cache security group ID from the security-groups module
- the Redis port used by the ECS-to-cache security group rule

The environment roots pass the cache security group only when the cache is enabled. There is no public subnet placement and no public CIDR ingress rule for Redis/Valkey.

Endpoints are outputs for wiring and review only. They are not credentials.

## Security notes

The module enables at-rest and in-transit encryption by default. Committed examples keep user-owned KMS key inputs as `null` so no real key ARN is stored in this public repo.

This module does **not** manage a Redis AUTH token, ACL user group, or application connection-string secret. Those values are sensitive and should be created through a secure secret-management workflow outside this public repository, then referenced by applications through AWS Secrets Manager. The current `secrets-manager-references` module covers ECS service secret references and can be extended by a user-owned design for cache connection secrets.

Production use should review:

- whether Redis AUTH/ACLs are required for the engine/version
- TLS client compatibility when transit encryption is enabled
- KMS key policy alignment when using customer-managed keys
- per-service access to cache connection secret references
- cache eviction policy and parameter group settings
- whether cache data can contain regulated or tenant-sensitive content

## Cost implications

ElastiCache can create ongoing cloud cost when manually provisioned. Cost drivers include:

- node type
- total cache node count (`replica_count + 1`)
- Multi-AZ and automatic failover requiring replicas
- snapshot retention and final snapshots
- data transfer between services and cache nodes
- KMS usage when customer-managed keys are supplied

Dev examples keep the cache disabled by default and use a small node shape if enabled. Prod examples enable the cache to show the optional private tier, with one replica and Multi-AZ/failover intent.

Costs change, so this module does not claim exact prices.

## Production hardening gaps

This portfolio module intentionally leaves several production decisions explicit rather than hiding them:

- no cluster-mode/sharded topology
- no global datastore or cross-region replication
- no custom parameter group managed here
- no Redis AUTH token or ACL user group
- no CloudWatch alarms or dashboards yet
- no slow-log/engine-log delivery yet
- no backup restore workflow or load testing guidance
- no per-service cache access policy beyond the network boundary

Use this as a reviewable base pattern, not a complete production cache platform.

## Inputs and outputs

Important inputs:

- `enabled`
- `private_subnet_ids`
- `security_group_ids`
- `engine`
- `engine_version`
- `node_type`
- `replica_count`
- `automatic_failover_enabled`
- `multi_az_enabled`
- `snapshot_retention_days`

Important outputs:

- `subnet_group_name`
- `replication_group_id`
- `replication_group_arn`
- `primary_endpoint_address`
- `reader_endpoint_address`
- `availability_summary`
- `security_summary`
- `snapshot_summary`
- `connection_reference_summary`
