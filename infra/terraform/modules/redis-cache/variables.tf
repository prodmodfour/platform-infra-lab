variable "enabled" {
  description = "Whether to create the ElastiCache Redis/Valkey resources. Disabled environments create no cache resources."
  type        = bool
  default     = false
}

variable "name_prefix" {
  description = "Public-safe prefix used for Redis/Valkey cache resource names."
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
  description = "Private subnet IDs for the ElastiCache subnet group. Use at least two subnets for the platform pattern."
  type        = list(string)

  validation {
    condition     = length(var.private_subnet_ids) >= 2
    error_message = "private_subnet_ids must include at least two private subnets."
  }
}

variable "security_group_ids" {
  description = "Security group IDs attached to the cache. Pass the private Redis cache security group when enabled; pass an empty list when disabled."
  type        = list(string)
  default     = []
}

variable "engine" {
  description = "Cache engine. Use redis for Redis OSS or valkey where supported by the selected AWS provider and region."
  type        = string
  default     = "redis"

  validation {
    condition     = contains(["redis", "valkey"], var.engine)
    error_message = "engine must be redis or valkey."
  }
}

variable "engine_version" {
  description = "Redis/Valkey engine version. Review regional support before manual provisioning."
  type        = string
  default     = "7.1"

  validation {
    condition     = length(trimspace(var.engine_version)) > 0
    error_message = "engine_version must not be empty."
  }
}

variable "node_type" {
  description = "ElastiCache node type. Dev examples should stay small; production examples should be reviewed for workload needs."
  type        = string
  default     = "cache.t4g.micro"

  validation {
    condition     = startswith(var.node_type, "cache.")
    error_message = "node_type must look like an ElastiCache node type such as cache.t4g.micro."
  }
}

variable "port" {
  description = "Redis/Valkey listener port exposed inside the private network."
  type        = number
  default     = 6379

  validation {
    condition     = var.port >= 1 && var.port <= 65535
    error_message = "port must be a valid TCP port."
  }
}

variable "parameter_group_name" {
  description = "Optional ElastiCache parameter group name. Keep null to use the AWS default for the selected engine/version."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = var.parameter_group_name == null ? true : length(trimspace(var.parameter_group_name)) > 0
    error_message = "parameter_group_name must be null or a non-empty parameter group name."
  }
}

variable "replica_count" {
  description = "Number of read replicas for the primary cache node. Total cache nodes are replica_count + 1."
  type        = number
  default     = 0

  validation {
    condition     = var.replica_count >= 0 && var.replica_count <= 5
    error_message = "replica_count must be between 0 and 5 for this reviewable cache pattern."
  }
}

variable "automatic_failover_enabled" {
  description = "Whether ElastiCache can promote a replica when the primary fails. Requires at least one replica."
  type        = bool
  default     = false
}

variable "multi_az_enabled" {
  description = "Whether Multi-AZ support is enabled for the replication group. Requires at least one replica."
  type        = bool
  default     = false
}

variable "at_rest_encryption_enabled" {
  description = "Whether ElastiCache at-rest encryption is enabled. Keep true unless a reviewed exception exists."
  type        = bool
  default     = true
}

variable "transit_encryption_enabled" {
  description = "Whether in-transit encryption is enabled for cache client traffic. Production should keep this enabled and validate client TLS support."
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "Optional user-owned KMS key ID/ARN for cache at-rest encryption. Keep null in committed examples."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = var.kms_key_id == null ? true : length(trimspace(var.kms_key_id)) > 0
    error_message = "kms_key_id must be null or a non-empty KMS key identifier."
  }
}

variable "snapshot_retention_days" {
  description = "Number of days to retain automatic cache snapshots. Use 0 to disable snapshots for disposable environments."
  type        = number
  default     = 0

  validation {
    condition     = var.snapshot_retention_days >= 0 && var.snapshot_retention_days <= 35
    error_message = "snapshot_retention_days must be between 0 and 35."
  }
}

variable "snapshot_window" {
  description = "Optional UTC snapshot window in hh:mm-hh:mm format. Keep null when snapshots are disabled."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = var.snapshot_window == null ? true : can(regex("^[0-2][0-9]:[0-5][0-9]-[0-2][0-9]:[0-5][0-9]$", var.snapshot_window))
    error_message = "snapshot_window must be null or use hh:mm-hh:mm format."
  }
}

variable "final_snapshot_identifier" {
  description = "Optional final snapshot identifier used during user-owned deletion. Keep null for disposable dev examples."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = var.final_snapshot_identifier == null ? true : can(regex("^[a-z][a-z0-9-]+$", var.final_snapshot_identifier))
    error_message = "final_snapshot_identifier must be lowercase kebab-case when provided."
  }
}

variable "maintenance_window" {
  description = "Preferred UTC maintenance window such as sun:05:00-sun:06:00."
  type        = string
  default     = "sun:05:00-sun:06:00"

  validation {
    condition     = can(regex("^(mon|tue|wed|thu|fri|sat|sun):[0-2][0-9]:[0-5][0-9]-(mon|tue|wed|thu|fri|sat|sun):[0-2][0-9]:[0-5][0-9]$", var.maintenance_window))
    error_message = "maintenance_window must use ddd:hh:mm-ddd:hh:mm format with lowercase day names."
  }
}

variable "apply_immediately" {
  description = "Whether cache changes apply immediately instead of during the maintenance window. Keep false for reviewable operations."
  type        = bool
  default     = false
}

variable "auto_minor_version_upgrade" {
  description = "Whether ElastiCache may apply supported minor engine upgrades during maintenance windows."
  type        = bool
  default     = true
}

variable "common_tags" {
  description = "Common public-safe tags applied to taggable cache resources."
  type        = map(string)
  default     = {}
}
