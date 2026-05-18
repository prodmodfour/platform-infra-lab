variable "name_prefix" {
  description = "Public-safe prefix used for PostgreSQL resource names."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]+$", var.name_prefix))
    error_message = "name_prefix must be lowercase kebab-case."
  }
}

variable "environment" {
  description = "Environment name used for tags and review context."
  type        = string

  validation {
    condition     = length(trimspace(var.environment)) > 0
    error_message = "environment must not be empty."
  }
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for the RDS subnet group. Use at least two subnets for the platform pattern."
  type        = list(string)

  validation {
    condition     = length(var.private_subnet_ids) >= 2
    error_message = "private_subnet_ids must include at least two private subnets."
  }
}

variable "security_group_ids" {
  description = "Security group IDs attached to the PostgreSQL instance. Pass the private RDS security group from the security-groups module."
  type        = list(string)

  validation {
    condition     = length(var.security_group_ids) > 0
    error_message = "security_group_ids must include at least one security group."
  }
}

variable "database_name" {
  description = "Initial PostgreSQL database name. This is not a secret."
  type        = string
  default     = "appdb"

  validation {
    condition     = can(regex("^[A-Za-z][A-Za-z0-9_]{0,62}$", var.database_name))
    error_message = "database_name must start with a letter and contain only letters, numbers, or underscores."
  }
}

variable "master_username" {
  description = "Master username for the RDS-managed credential. This is not the password and should remain generic."
  type        = string
  default     = "appadmin"

  validation {
    condition     = can(regex("^[A-Za-z][A-Za-z0-9_]{0,62}$", var.master_username)) && lower(var.master_username) != "postgres"
    error_message = "master_username must start with a letter, contain only letters/numbers/underscores, and avoid the reserved postgres username."
  }
}

variable "engine_version" {
  description = "PostgreSQL engine version for the instance. Review against AWS regional support before manual provisioning."
  type        = string
  default     = "16.3"

  validation {
    condition     = length(trimspace(var.engine_version)) > 0
    error_message = "engine_version must not be empty."
  }
}

variable "instance_class" {
  description = "RDS instance class. Dev should stay small; production examples should be reviewed for workload needs."
  type        = string
  default     = "db.t4g.micro"

  validation {
    condition     = startswith(var.instance_class, "db.")
    error_message = "instance_class must look like an RDS instance class such as db.t4g.micro."
  }
}

variable "port" {
  description = "PostgreSQL listener port."
  type        = number
  default     = 5432

  validation {
    condition     = var.port >= 1 && var.port <= 65535
    error_message = "port must be a valid TCP port."
  }
}

variable "allocated_storage_gib" {
  description = "Initial allocated storage in GiB."
  type        = number
  default     = 20

  validation {
    condition     = var.allocated_storage_gib >= 20
    error_message = "allocated_storage_gib must be at least 20 for this PostgreSQL pattern."
  }
}

variable "max_allocated_storage_gib" {
  description = "Optional autoscaling storage ceiling in GiB. Set null to disable storage autoscaling."
  type        = number
  default     = null
  nullable    = true
}

variable "storage_type" {
  description = "RDS storage type. gp3 is the default for the public-safe examples."
  type        = string
  default     = "gp3"

  validation {
    condition     = contains(["gp2", "gp3", "io1", "io2"], var.storage_type)
    error_message = "storage_type must be one of gp2, gp3, io1, or io2."
  }
}

variable "storage_encrypted" {
  description = "Whether RDS storage encryption is enabled. Keep true unless a reviewed exception exists."
  type        = bool
  default     = true
}

variable "storage_kms_key_id" {
  description = "Optional user-owned KMS key ID/ARN for RDS storage encryption. Keep null in committed examples."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = var.storage_kms_key_id == null ? true : length(trimspace(var.storage_kms_key_id)) > 0
    error_message = "storage_kms_key_id must be null or a non-empty KMS key identifier."
  }
}

variable "master_user_secret_kms_key_id" {
  description = "Optional user-owned KMS key ID/ARN for the RDS-managed master user secret. Keep null in committed examples."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = var.master_user_secret_kms_key_id == null ? true : length(trimspace(var.master_user_secret_kms_key_id)) > 0
    error_message = "master_user_secret_kms_key_id must be null or a non-empty KMS key identifier."
  }
}

variable "multi_az" {
  description = "Whether to deploy a Multi-AZ standby for availability. This increases cost when manually provisioned."
  type        = bool
  default     = false
}

variable "backup_retention_days" {
  description = "Automated backup retention in days. Use a reviewed non-zero value for persistent environments."
  type        = number
  default     = 7

  validation {
    condition     = var.backup_retention_days >= 0 && var.backup_retention_days <= 35
    error_message = "backup_retention_days must be between 0 and 35."
  }
}

variable "preferred_backup_window" {
  description = "Preferred UTC backup window in hh:mm-hh:mm format."
  type        = string
  default     = "03:00-04:00"

  validation {
    condition     = can(regex("^[0-2][0-9]:[0-5][0-9]-[0-2][0-9]:[0-5][0-9]$", var.preferred_backup_window))
    error_message = "preferred_backup_window must use hh:mm-hh:mm format."
  }
}

variable "preferred_maintenance_window" {
  description = "Preferred UTC maintenance window such as sun:04:00-sun:05:00."
  type        = string
  default     = "sun:04:00-sun:05:00"

  validation {
    condition     = can(regex("^(mon|tue|wed|thu|fri|sat|sun):[0-2][0-9]:[0-5][0-9]-(mon|tue|wed|thu|fri|sat|sun):[0-2][0-9]:[0-5][0-9]$", var.preferred_maintenance_window))
    error_message = "preferred_maintenance_window must use ddd:hh:mm-ddd:hh:mm format with lowercase day names."
  }
}

variable "deletion_protection" {
  description = "Whether RDS deletion protection is enabled. Production-intent examples should enable this."
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Whether to skip a final snapshot on manual destroy. Dev may skip; production-intent examples should not."
  type        = bool
  default     = true
}

variable "final_snapshot_identifier" {
  description = "Optional final snapshot identifier used when skip_final_snapshot is false. Defaults to a public-safe generated name."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = var.final_snapshot_identifier == null ? true : can(regex("^[a-z][a-z0-9-]+$", var.final_snapshot_identifier))
    error_message = "final_snapshot_identifier must be lowercase kebab-case when provided."
  }
}

variable "delete_automated_backups" {
  description = "Whether automated backups are deleted with the instance during a user-owned destroy."
  type        = bool
  default     = true
}

variable "copy_tags_to_snapshot" {
  description = "Whether RDS tags are copied to snapshots for reviewability and cleanup."
  type        = bool
  default     = true
}

variable "auto_minor_version_upgrade" {
  description = "Whether RDS may apply minor engine version upgrades during maintenance windows."
  type        = bool
  default     = true
}

variable "apply_immediately" {
  description = "Whether changes apply immediately instead of during the maintenance window. Keep false for reviewable operations."
  type        = bool
  default     = false
}

variable "enabled_cloudwatch_logs_exports" {
  description = "PostgreSQL log exports to CloudWatch Logs. Values are references to log types, not log contents."
  type        = list(string)
  default     = ["postgresql", "upgrade"]

  validation {
    condition     = alltrue([for log_type in var.enabled_cloudwatch_logs_exports : contains(["postgresql", "upgrade"], log_type)])
    error_message = "enabled_cloudwatch_logs_exports may only contain postgresql and upgrade for this module."
  }
}

variable "monitoring_interval" {
  description = "Enhanced monitoring interval in seconds. Use 0 to disable unless a reviewed monitoring role ARN is supplied."
  type        = number
  default     = 0

  validation {
    condition     = contains([0, 1, 5, 10, 15, 30, 60], var.monitoring_interval)
    error_message = "monitoring_interval must be one of 0, 1, 5, 10, 15, 30, or 60."
  }
}

variable "monitoring_role_arn" {
  description = "IAM role ARN for RDS enhanced monitoring when monitoring_interval is greater than zero. Keep null in committed examples."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition = var.monitoring_role_arn == null ? true : can(regex(
      "^arn:aws[a-zA-Z-]*:iam::[0-9]{12}:role/.+",
      var.monitoring_role_arn
    ))
    error_message = "monitoring_role_arn must be an IAM role ARN when provided."
  }
}

variable "performance_insights_enabled" {
  description = "Whether to enable RDS Performance Insights/Database Insights for reviewable database metrics."
  type        = bool
  default     = false
}

variable "performance_insights_retention_period" {
  description = "Performance Insights retention period. AWS supports 7, 731, or month-sized multiples of 31 days."
  type        = number
  default     = 7

  validation {
    condition     = contains(concat([7, 731], [for month in range(1, 24) : month * 31]), var.performance_insights_retention_period)
    error_message = "performance_insights_retention_period must be 7, 731, or a multiple of 31 from 31 through 713."
  }
}

variable "performance_insights_kms_key_id" {
  description = "Optional KMS key ID/ARN for Performance Insights. Keep null in committed examples."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = var.performance_insights_kms_key_id == null ? true : length(trimspace(var.performance_insights_kms_key_id)) > 0
    error_message = "performance_insights_kms_key_id must be null or a non-empty KMS key identifier."
  }
}

variable "ca_cert_identifier" {
  description = "Optional RDS CA certificate identifier. Keep null unless a user-owned environment has reviewed certificate rotation."
  type        = string
  default     = null
  nullable    = true
}

variable "common_tags" {
  description = "Common public-safe tags applied to taggable RDS resources."
  type        = map(string)
  default     = {}
}
