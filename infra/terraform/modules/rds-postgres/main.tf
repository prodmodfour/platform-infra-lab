locals {
  component_tags = merge(var.common_tags, {
    Environment = var.environment
    Component   = "rds-postgres"
  })

  db_identifier             = "${var.name_prefix}-postgres"
  subnet_group_name         = "${var.name_prefix}-postgres-subnets"
  final_snapshot_identifier = var.final_snapshot_identifier == null ? "${var.name_prefix}-postgres-final" : var.final_snapshot_identifier

  credential_reference_summary = {
    credential_source                    = "rds-managed-secrets-manager-master-user-secret"
    secret_value_in_terraform            = false
    managed_master_user_password_enabled = true
    master_user_secret_kms_key_supplied  = var.master_user_secret_kms_key_id != null
  }
}

resource "aws_db_subnet_group" "this" {
  name        = local.subnet_group_name
  description = "Private subnet group for the PostgreSQL instance"
  subnet_ids  = var.private_subnet_ids

  tags = merge(local.component_tags, {
    Name = local.subnet_group_name
    Tier = "private-data"
  })
}

resource "aws_db_instance" "this" {
  identifier = local.db_identifier

  engine         = "postgres"
  engine_version = var.engine_version
  instance_class = var.instance_class
  db_name        = var.database_name
  username       = var.master_username
  port           = var.port

  manage_master_user_password   = true
  master_user_secret_kms_key_id = var.master_user_secret_kms_key_id

  allocated_storage     = var.allocated_storage_gib
  max_allocated_storage = var.max_allocated_storage_gib
  storage_type          = var.storage_type
  storage_encrypted     = var.storage_encrypted
  kms_key_id            = var.storage_kms_key_id

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = var.security_group_ids
  publicly_accessible    = false
  multi_az               = var.multi_az

  backup_retention_period   = var.backup_retention_days
  backup_window             = var.preferred_backup_window
  maintenance_window        = var.preferred_maintenance_window
  copy_tags_to_snapshot     = var.copy_tags_to_snapshot
  deletion_protection       = var.deletion_protection
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : local.final_snapshot_identifier
  delete_automated_backups  = var.delete_automated_backups

  auto_minor_version_upgrade = var.auto_minor_version_upgrade
  apply_immediately          = var.apply_immediately
  ca_cert_identifier         = var.ca_cert_identifier

  enabled_cloudwatch_logs_exports       = var.enabled_cloudwatch_logs_exports
  monitoring_interval                   = var.monitoring_interval
  monitoring_role_arn                   = var.monitoring_interval > 0 ? var.monitoring_role_arn : null
  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_enabled ? var.performance_insights_retention_period : null
  performance_insights_kms_key_id       = var.performance_insights_enabled ? var.performance_insights_kms_key_id : null

  tags = merge(local.component_tags, {
    Name = local.db_identifier
    Tier = "private-data"
  })

  lifecycle {
    precondition {
      condition     = length(local.db_identifier) <= 63
      error_message = "RDS instance identifiers must be 63 characters or fewer; shorten name_prefix."
    }

    precondition {
      condition     = var.max_allocated_storage_gib == null ? true : var.max_allocated_storage_gib >= var.allocated_storage_gib
      error_message = "max_allocated_storage_gib must be null or greater than/equal to allocated_storage_gib."
    }

    precondition {
      condition     = var.monitoring_interval == 0 ? true : var.monitoring_role_arn != null
      error_message = "monitoring_role_arn is required when monitoring_interval is greater than zero."
    }
  }
}
