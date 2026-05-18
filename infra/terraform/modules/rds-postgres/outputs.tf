output "db_subnet_group_name" {
  description = "Name of the private DB subnet group."
  value       = aws_db_subnet_group.this.name
}

output "db_instance_identifier" {
  description = "RDS PostgreSQL instance identifier."
  value       = aws_db_instance.this.identifier
}

output "db_instance_arn" {
  description = "RDS PostgreSQL instance ARN."
  value       = aws_db_instance.this.arn
}

output "db_instance_resource_id" {
  description = "Stable RDS resource ID used by monitoring integrations."
  value       = aws_db_instance.this.resource_id
}

output "endpoint" {
  description = "RDS endpoint including port. This is not a credential."
  value       = aws_db_instance.this.endpoint
}

output "address" {
  description = "RDS hostname/address. This is not a credential."
  value       = aws_db_instance.this.address
}

output "port" {
  description = "PostgreSQL port exposed inside the private network."
  value       = aws_db_instance.this.port
}

output "database_name" {
  description = "Initial database name configured on the PostgreSQL instance."
  value       = aws_db_instance.this.db_name
}

output "master_username" {
  description = "Master username configured for the RDS-managed credential. This is not the password."
  value       = aws_db_instance.this.username
}

output "master_user_secret_arn" {
  description = "Secrets Manager ARN for the RDS-managed master user secret when created by AWS. This is a reference, not a secret value."
  value       = try(aws_db_instance.this.master_user_secret[0].secret_arn, null)
}

output "credential_reference_summary" {
  description = "Review-friendly summary of the credential pattern; no secret values are exposed."
  value       = local.credential_reference_summary
}

output "publicly_accessible" {
  description = "Whether the RDS instance is publicly accessible. This module fixes it to false."
  value       = aws_db_instance.this.publicly_accessible
}

output "backup_summary" {
  description = "Review-friendly summary of backup and deletion-protection settings."
  value = {
    backup_retention_days     = var.backup_retention_days
    backup_window             = var.preferred_backup_window
    maintenance_window        = var.preferred_maintenance_window
    deletion_protection       = var.deletion_protection
    skip_final_snapshot       = var.skip_final_snapshot
    final_snapshot_identifier = var.skip_final_snapshot ? null : local.final_snapshot_identifier
    delete_automated_backups  = var.delete_automated_backups
    copy_tags_to_snapshot     = var.copy_tags_to_snapshot
  }
}

output "storage_summary" {
  description = "Review-friendly summary of storage settings."
  value = {
    allocated_storage_gib      = var.allocated_storage_gib
    max_allocated_storage_gib  = var.max_allocated_storage_gib
    storage_type               = var.storage_type
    storage_encrypted          = var.storage_encrypted
    storage_kms_key_supplied   = var.storage_kms_key_id != null
    multi_az                   = var.multi_az
    auto_minor_version_upgrade = var.auto_minor_version_upgrade
  }
}

output "monitoring_summary" {
  description = "Review-friendly summary of database monitoring settings."
  value = {
    enabled_cloudwatch_logs_exports       = var.enabled_cloudwatch_logs_exports
    enhanced_monitoring_interval_seconds  = var.monitoring_interval
    enhanced_monitoring_role_supplied     = var.monitoring_role_arn != null
    performance_insights_enabled          = var.performance_insights_enabled
    performance_insights_retention_period = var.performance_insights_enabled ? var.performance_insights_retention_period : null
    performance_insights_kms_key_supplied = var.performance_insights_kms_key_id != null
  }
}
