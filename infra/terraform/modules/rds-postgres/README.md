# RDS PostgreSQL module

This module models a private Amazon RDS for PostgreSQL instance for the public-safe container platform lab.

It is intentionally reviewable rather than production-complete. It creates a subnet group over private subnets and an RDS PostgreSQL instance that is reachable only through caller-supplied private security groups.

## Resources

- `aws_db_subnet_group.this`
- `aws_db_instance.this`

## Private database design

The module fixes `publicly_accessible = false` and expects private subnet IDs from the environment network module. It does not create public ingress rules. Environments should pass the RDS security group from `modules/security-groups`, where ingress is limited to the ECS service security group on the PostgreSQL port.

The intended traffic path is:

```text
public internet -> ALB security group -> ECS service security group -> RDS PostgreSQL security group
```

There is no direct public path to the database.

## Credentials and secret references

No database password value is accepted by this module and no password is committed to the repository.

The module uses RDS-managed master user password support:

```hcl
manage_master_user_password = true
```

If a user manually provisions the lab, AWS creates and stores the master credential in Secrets Manager. The module outputs `master_user_secret_arn` as a reference only. The secret value itself is not read by Terraform code in this repository, not written to examples, and not exposed in outputs.

Application connection strings should be stored as separate user-owned Secrets Manager or SSM Parameter Store references outside this repository or by a secure user-owned pipeline. The existing ECS service examples continue to use placeholder secret-reference ARNs for `DATABASE_URL`.

## Backups and deletion protection

The module exposes reviewable variables for:

- `backup_retention_days`
- `preferred_backup_window`
- `preferred_maintenance_window`
- `deletion_protection`
- `skip_final_snapshot`
- `final_snapshot_identifier`
- `delete_automated_backups`
- `copy_tags_to_snapshot`

Dev can stay disposable with shorter retention and skipped final snapshots. Production-intent examples should enable deletion protection, use non-zero backup retention, and keep a final snapshot path unless an operator explicitly accepts the data-loss risk.

## Storage and availability

The module exposes:

- `allocated_storage_gib`
- `max_allocated_storage_gib`
- `storage_type`
- `storage_encrypted`
- `storage_kms_key_id`
- `multi_az`
- `instance_class`

Storage encryption defaults to enabled. KMS inputs are optional and must be user-owned if supplied. Dev examples use small single-AZ sizing; prod examples show Multi-AZ and larger storage to demonstrate production intent.

## Monitoring-related settings

The module models practical database observability inputs without adding a full observability stack yet:

- PostgreSQL and upgrade log exports through `enabled_cloudwatch_logs_exports`
- optional Enhanced Monitoring through `monitoring_interval` and `monitoring_role_arn`
- optional Performance Insights/Database Insights through `performance_insights_enabled`

Enhanced Monitoring is disabled in committed examples because it requires a reviewed IAM role. The future observability module will add dashboards and alarms that can consume RDS identifiers and metrics.

## Cost implications

RDS can be a meaningful ongoing cost driver when manually provisioned. Cost depends on qualitative drivers such as:

- instance class
- single-AZ versus Multi-AZ
- allocated and autoscaled storage
- backup and snapshot retention
- log exports and metric retention
- Performance Insights/Database Insights settings
- KMS usage
- data transfer and private egress patterns

This repository does not claim exact current AWS prices. Any manual provisioning is optional, user-owned, and can incur cloud cost.

## Migration considerations

Database schema changes should be handled by application-owned migration tooling or a reviewed release process, not by ad-hoc manual changes in this module.

Before a real migration, review:

- whether the migration is backward compatible with the currently deployed tasks
- backup/snapshot freshness
- rollback path for schema and data changes
- migration runtime and lock risk
- whether migrations run once, outside horizontally scaled app startup paths
- how secrets and connection strings are rotated or updated

## Production hardening gaps

Before real production use, review at least:

- engine version and regional availability
- instance class, storage, IOPS, and connection limits
- Multi-AZ strategy and cross-region recovery requirements
- backup retention, PITR expectations, and restore testing
- deletion protection and final snapshot policy
- customer-managed KMS keys and key policies
- parameter groups and database flags
- IAM database authentication needs
- network egress, VPC endpoints, and DNS resolution
- RDS Proxy or connection pooling
- audit logging, alarms, dashboards, and paging integration
- least-privilege database users beyond the master credential

## Example

```hcl
module "rds_postgres" {
  source = "../../modules/rds-postgres"

  name_prefix        = local.name_prefix
  environment        = local.environment
  private_subnet_ids = module.network.private_subnet_ids
  security_group_ids = [module.security_groups.rds_postgres_security_group_id]

  database_name        = "appdb"
  master_username      = "appadmin"
  instance_class       = "db.t4g.micro"
  allocated_storage_gib = 20
  backup_retention_days = 3
  deletion_protection   = false

  common_tags = local.common_tags
}
```
