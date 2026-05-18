variable "aws_region" {
  description = "AWS region used for validation and future resources. Use a public-safe placeholder in examples."
  type        = string
  default     = "us-east-1"

  validation {
    condition     = length(trimspace(var.aws_region)) > 0
    error_message = "aws_region must not be empty."
  }
}

variable "project_name" {
  description = "Public-safe project name used for naming and tags."
  type        = string
  default     = "platform-infra-lab"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]+$", var.project_name))
    error_message = "project_name must be lowercase kebab-case."
  }
}

variable "environment_name" {
  description = "Environment name for this root module."
  type        = string
  default     = "prod"

  validation {
    condition     = var.environment_name == "prod"
    error_message = "The prod environment root must use environment_name = \"prod\"."
  }
}

variable "additional_tags" {
  description = "Additional public-safe tags merged with the common tag set. Do not include secrets, private names, or account IDs."
  type        = map(string)
  default     = {}
}

variable "vpc_cidr" {
  description = "CIDR block for the prod VPC."
  type        = string
  default     = "10.30.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "vpc_cidr must be a valid CIDR block."
  }
}

variable "availability_zones" {
  description = "Availability zone names used by the network module for subnet placement."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]

  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "At least two availability zones should be shown for the platform pattern."
  }
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets such as the ALB edge."
  type        = list(string)
  default     = ["10.30.0.0/24", "10.30.1.0/24", "10.30.2.0/24"]

  validation {
    condition     = length(var.public_subnet_cidrs) >= 2 && alltrue([for cidr in var.public_subnet_cidrs : can(cidrnetmask(cidr))])
    error_message = "public_subnet_cidrs must contain at least two valid CIDR blocks."
  }
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private ECS, database, and cache subnet placement."
  type        = list(string)
  default     = ["10.30.10.0/24", "10.30.11.0/24", "10.30.12.0/24"]

  validation {
    condition     = length(var.private_subnet_cidrs) >= 2 && alltrue([for cidr in var.private_subnet_cidrs : can(cidrnetmask(cidr))])
    error_message = "private_subnet_cidrs must contain at least two valid CIDR blocks."
  }
}

variable "enable_nat_gateway" {
  description = "Network module flag. Prod shows production intent with NAT enabled for private egress review."
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Default CloudWatch log retention days for future prod service log groups."
  type        = number
  default     = 30

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3653], var.log_retention_days)
    error_message = "log_retention_days must match a CloudWatch Logs retention option."
  }
}

variable "deletion_protection_enabled" {
  description = "Future stateful-service deletion protection default. Prod enables this to show production-intent review posture."
  type        = bool
  default     = true
}

variable "enable_redis" {
  description = "Redis/ElastiCache module flag. Prod example enables the optional private cache tier for review."
  type        = bool
  default     = true
}

variable "service_desired_count_default" {
  description = "Default desired task count for prod ECS service examples. Kept for review summaries; per-service desired counts live in ecs_services."
  type        = number
  default     = 2

  validation {
    condition     = var.service_desired_count_default >= 1
    error_message = "service_desired_count_default must be at least 1."
  }
}

variable "create_ecs_listener_rules" {
  description = "Whether ECS service modules should create ALB listener rules against the environment load-balancer module."
  type        = bool
  default     = true
}

variable "ecs_listener_arn" {
  description = "Optional override ALB listener ARN used when create_ecs_listener_rules is true. Leave null to use module.load_balancer.http_listener_arn."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition = var.ecs_listener_arn == null ? true : can(regex(
      "^arn:aws[a-zA-Z-]*:elasticloadbalancing:[a-z0-9-]+:[0-9]{12}:listener/app/.+",
      var.ecs_listener_arn
    ))
    error_message = "ecs_listener_arn must be an ALB listener ARN when provided."
  }
}

variable "load_balancer_internal" {
  description = "Whether the Application Load Balancer is internal. Prod defaults to false to model the public edge."
  type        = bool
  default     = false
}

variable "load_balancer_deletion_protection_enabled" {
  description = "Whether ALB deletion protection is enabled. Prod enables this to show production-intent review posture."
  type        = bool
  default     = true
}

variable "load_balancer_http_listener_port" {
  description = "HTTP listener port for the public Application Load Balancer."
  type        = number
  default     = 80

  validation {
    condition     = var.load_balancer_http_listener_port >= 1 && var.load_balancer_http_listener_port <= 65535
    error_message = "load_balancer_http_listener_port must be a valid TCP port."
  }
}

variable "enable_load_balancer_https_listener" {
  description = "Whether to create an optional HTTPS listener. Keep false in committed examples because no real cert ARN is stored."
  type        = bool
  default     = false
}

variable "load_balancer_https_listener_port" {
  description = "HTTPS listener port when the optional HTTPS listener is enabled."
  type        = number
  default     = 443

  validation {
    condition     = var.load_balancer_https_listener_port >= 1 && var.load_balancer_https_listener_port <= 65535
    error_message = "load_balancer_https_listener_port must be a valid TCP port."
  }
}

variable "load_balancer_https_certificate_arn" {
  description = "Optional ACM certificate ARN for HTTPS. Keep null in committed examples; use only user-owned values outside this repo."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition = var.load_balancer_https_certificate_arn == null ? true : can(regex(
      "^arn:aws[a-zA-Z-]*:acm:[a-z0-9-]+:[0-9]{12}:certificate/.+",
      var.load_balancer_https_certificate_arn
    ))
    error_message = "load_balancer_https_certificate_arn must be an ACM certificate ARN when provided."
  }
}

variable "load_balancer_https_ssl_policy" {
  description = "SSL policy for the optional HTTPS listener. Review before real production use."
  type        = string
  default     = "ELBSecurityPolicy-2016-08"

  validation {
    condition     = length(trimspace(var.load_balancer_https_ssl_policy)) > 0
    error_message = "load_balancer_https_ssl_policy must not be empty."
  }
}

variable "load_balancer_access_logs_enabled" {
  description = "Whether ALB access logs are enabled. Prod keeps this false because no real log bucket is committed."
  type        = bool
  default     = false
}

variable "load_balancer_access_logs_bucket" {
  description = "Existing user-owned S3 bucket for ALB access logs when enabled. Keep null in committed examples."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition = var.load_balancer_access_logs_bucket == null ? true : can(regex(
      "^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$",
      var.load_balancer_access_logs_bucket
    ))
    error_message = "load_balancer_access_logs_bucket must look like an S3 bucket name when provided."
  }
}

variable "load_balancer_access_logs_prefix" {
  description = "Optional prefix for ALB access logs. Defaults inside the module when null."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = var.load_balancer_access_logs_prefix == null ? true : !startswith(var.load_balancer_access_logs_prefix, "/")
    error_message = "load_balancer_access_logs_prefix must be relative and must not start with /."
  }
}

variable "ecs_services" {
  description = "Public-safe ECS/Fargate service examples keyed by service name. Images and secret references must be placeholders only."
  type = map(object({
    image                           = string
    container_port                  = number
    cpu                             = number
    memory                          = number
    desired_count                   = number
    health_check_path               = string
    listener_rule_priority          = number
    listener_rule_path_patterns     = list(string)
    environment_variables           = map(string)
    secret_references               = map(string)
    enable_autoscaling              = bool
    autoscaling_min_capacity        = number
    autoscaling_max_capacity        = number
    autoscaling_cpu_target_value    = number
    autoscaling_memory_target_value = number
  }))
  default = {
    carbon-platform-api = {
      image                       = "public.ecr.aws/example/carbon-platform-api:demo"
      container_port              = 8080
      cpu                         = 512
      memory                      = 1024
      desired_count               = 2
      health_check_path           = "/health"
      listener_rule_priority      = 110
      listener_rule_path_patterns = ["/carbon*", "/carbon/*"]
      environment_variables = {
        LOG_LEVEL     = "info"
        DATABASE_MODE = "placeholder"
      }
      secret_references = {
        DATABASE_URL = "arn:aws:secretsmanager:us-east-1:123456789012:secret:platform-infra-lab/prod/ecs-execution/carbon-platform-api/database-url-demo"
      }
      enable_autoscaling              = true
      autoscaling_min_capacity        = 2
      autoscaling_max_capacity        = 6
      autoscaling_cpu_target_value    = 55
      autoscaling_memory_target_value = 70
    }
    job-runner-platform = {
      image                       = "public.ecr.aws/example/job-runner-platform:demo"
      container_port              = 8080
      cpu                         = 512
      memory                      = 1024
      desired_count               = 2
      health_check_path           = "/healthz"
      listener_rule_priority      = 120
      listener_rule_path_patterns = ["/jobs*", "/jobs/*"]
      environment_variables = {
        LOG_LEVEL   = "info"
        WORKER_MODE = "demo"
        QUEUE_NAME  = "demo-jobs"
      }
      secret_references = {
        JOB_RUNNER_API_KEY = "arn:aws:ssm:us-east-1:123456789012:parameter/platform-infra-lab/prod/ecs-execution/job-runner-platform/api-key-demo"
      }
      enable_autoscaling              = true
      autoscaling_min_capacity        = 2
      autoscaling_max_capacity        = 4
      autoscaling_cpu_target_value    = 60
      autoscaling_memory_target_value = 75
    }
    multi-tenant-saas-api = {
      image                       = "public.ecr.aws/example/multi-tenant-saas-api:demo"
      container_port              = 8080
      cpu                         = 512
      memory                      = 1024
      desired_count               = 2
      health_check_path           = "/ready"
      listener_rule_priority      = 130
      listener_rule_path_patterns = ["/saas*", "/saas/*"]
      environment_variables = {
        LOG_LEVEL     = "info"
        TENANCY_MODE  = "demo"
        DATABASE_MODE = "placeholder"
      }
      secret_references = {
        DATABASE_URL    = "arn:aws:secretsmanager:us-east-1:123456789012:secret:platform-infra-lab/prod/ecs-execution/multi-tenant-saas-api/database-url-demo"
        JWT_SIGNING_KEY = "arn:aws:ssm:us-east-1:123456789012:parameter/platform-infra-lab/prod/ecs-execution/multi-tenant-saas-api/jwt-signing-key-demo"
      }
      enable_autoscaling              = true
      autoscaling_min_capacity        = 2
      autoscaling_max_capacity        = 6
      autoscaling_cpu_target_value    = 55
      autoscaling_memory_target_value = 70
    }
  }

  validation {
    condition     = length(var.ecs_services) > 0
    error_message = "ecs_services must include at least one service example."
  }

  validation {
    condition = alltrue([
      for service_name, config in var.ecs_services :
      can(regex("^[a-z][a-z0-9-]+$", service_name)) &&
      can(regex("^public\\.ecr\\.aws/example/[a-z0-9-]+:demo$", config.image)) &&
      config.container_port >= 1 && config.container_port <= 65535 &&
      contains([256, 512, 1024, 2048, 4096], config.cpu) &&
      config.memory >= 512 &&
      config.desired_count >= 1 &&
      startswith(config.health_check_path, "/") &&
      config.listener_rule_priority >= 1 && config.listener_rule_priority <= 50000 &&
      config.autoscaling_min_capacity >= 1 &&
      config.autoscaling_max_capacity >= config.autoscaling_min_capacity &&
      config.autoscaling_cpu_target_value > 0 && config.autoscaling_cpu_target_value <= 100 &&
      config.autoscaling_memory_target_value > 0 && config.autoscaling_memory_target_value <= 100
    ])
    error_message = "ecs_services entries must use fake images, valid ports/sizing, health paths, listener priorities, and autoscaling ranges."
  }

  validation {
    condition = alltrue(flatten([
      for _, config in var.ecs_services : [
        for name in concat(keys(config.environment_variables), keys(config.secret_references)) :
        can(regex("^[A-Z_][A-Z0-9_]*$", name))
      ]
    ]))
    error_message = "ECS environment variable and secret names must be uppercase shell-style identifiers."
  }

  validation {
    condition = alltrue(flatten([
      for _, config in var.ecs_services : [
        for arn in values(config.secret_references) :
        can(regex("^arn:aws[a-zA-Z-]*:secretsmanager:[a-z0-9-]+:[0-9]{12}:secret:.+", arn)) ||
        can(regex("^arn:aws[a-zA-Z-]*:ssm:[a-z0-9-]+:[0-9]{12}:parameter/.+", arn))
      ]
    ]))
    error_message = "ECS secret references must be Secrets Manager or SSM Parameter Store ARNs, not values."
  }
}

variable "alb_ingress_cidrs" {
  description = "IPv4 CIDR blocks allowed to reach the public ALB. Prod keeps the edge public in this placeholder but production should review WAF/trusted CIDR restrictions."
  type        = list(string)
  default     = ["0.0.0.0/0"]

  validation {
    condition     = length(var.alb_ingress_cidrs) > 0 && alltrue([for cidr in var.alb_ingress_cidrs : can(cidrnetmask(cidr))])
    error_message = "alb_ingress_cidrs must contain at least one valid IPv4 CIDR block."
  }
}

variable "alb_ingress_ports" {
  description = "TCP ports exposed on the public ALB security group. Prod includes HTTP now; add HTTPS only with a reviewed certificate and ingress rule."
  type        = list(number)
  default     = [80]

  validation {
    condition     = length(var.alb_ingress_ports) > 0 && alltrue([for port in var.alb_ingress_ports : port >= 1 && port <= 65535])
    error_message = "alb_ingress_ports must contain valid TCP port numbers."
  }
}

variable "service_port" {
  description = "Application port allowed from the ALB security group to private ECS services."
  type        = number
  default     = 8080

  validation {
    condition     = var.service_port >= 1 && var.service_port <= 65535
    error_message = "service_port must be a valid TCP port."
  }
}

variable "database_port" {
  description = "PostgreSQL port allowed from private ECS services to the private RDS security group."
  type        = number
  default     = 5432

  validation {
    condition     = var.database_port >= 1 && var.database_port <= 65535
    error_message = "database_port must be a valid TCP port."
  }
}

variable "rds_database_name" {
  description = "Initial PostgreSQL database name for the prod RDS instance. This is not a secret."
  type        = string
  default     = "appdb"

  validation {
    condition     = can(regex("^[A-Za-z][A-Za-z0-9_]{0,62}$", var.rds_database_name))
    error_message = "rds_database_name must start with a letter and contain only letters, numbers, or underscores."
  }
}

variable "rds_master_username" {
  description = "Master username for the RDS-managed PostgreSQL credential. This is not the password."
  type        = string
  default     = "appadmin"

  validation {
    condition     = can(regex("^[A-Za-z][A-Za-z0-9_]{0,62}$", var.rds_master_username)) && lower(var.rds_master_username) != "postgres"
    error_message = "rds_master_username must start with a letter, contain only letters/numbers/underscores, and avoid the reserved postgres username."
  }
}

variable "rds_engine_version" {
  description = "PostgreSQL engine version for the prod RDS example. Review regional support before manual provisioning."
  type        = string
  default     = "16.3"

  validation {
    condition     = length(trimspace(var.rds_engine_version)) > 0
    error_message = "rds_engine_version must not be empty."
  }
}

variable "rds_instance_class" {
  description = "RDS instance class for the prod PostgreSQL example."
  type        = string
  default     = "db.t4g.small"

  validation {
    condition     = startswith(var.rds_instance_class, "db.")
    error_message = "rds_instance_class must look like an RDS instance class such as db.t4g.micro."
  }
}

variable "rds_allocated_storage_gib" {
  description = "Initial allocated storage in GiB for the prod PostgreSQL instance."
  type        = number
  default     = 50

  validation {
    condition     = var.rds_allocated_storage_gib >= 20
    error_message = "rds_allocated_storage_gib must be at least 20."
  }
}

variable "rds_max_allocated_storage_gib" {
  description = "Optional storage autoscaling ceiling in GiB for PostgreSQL. Set null to disable storage autoscaling."
  type        = number
  default     = 200
  nullable    = true
}

variable "rds_storage_type" {
  description = "RDS storage type for PostgreSQL."
  type        = string
  default     = "gp3"

  validation {
    condition     = contains(["gp2", "gp3", "io1", "io2"], var.rds_storage_type)
    error_message = "rds_storage_type must be one of gp2, gp3, io1, or io2."
  }
}

variable "rds_storage_encrypted" {
  description = "Whether PostgreSQL storage encryption is enabled."
  type        = bool
  default     = true
}

variable "rds_storage_kms_key_id" {
  description = "Optional user-owned KMS key ID/ARN for RDS storage encryption. Keep null in committed examples."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = var.rds_storage_kms_key_id == null ? true : length(trimspace(var.rds_storage_kms_key_id)) > 0
    error_message = "rds_storage_kms_key_id must be null or a non-empty KMS key identifier."
  }
}

variable "rds_master_user_secret_kms_key_id" {
  description = "Optional user-owned KMS key ID/ARN for the RDS-managed master user secret. Keep null in committed examples."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = var.rds_master_user_secret_kms_key_id == null ? true : length(trimspace(var.rds_master_user_secret_kms_key_id)) > 0
    error_message = "rds_master_user_secret_kms_key_id must be null or a non-empty KMS key identifier."
  }
}

variable "rds_multi_az" {
  description = "Whether the PostgreSQL instance uses Multi-AZ. Prod enables this to demonstrate production-intent availability."
  type        = bool
  default     = true
}

variable "rds_backup_retention_days" {
  description = "Automated backup retention in days for PostgreSQL."
  type        = number
  default     = 14

  validation {
    condition     = var.rds_backup_retention_days >= 0 && var.rds_backup_retention_days <= 35
    error_message = "rds_backup_retention_days must be between 0 and 35."
  }
}

variable "rds_preferred_backup_window" {
  description = "Preferred UTC backup window for PostgreSQL in hh:mm-hh:mm format."
  type        = string
  default     = "03:00-04:00"

  validation {
    condition     = can(regex("^[0-2][0-9]:[0-5][0-9]-[0-2][0-9]:[0-5][0-9]$", var.rds_preferred_backup_window))
    error_message = "rds_preferred_backup_window must use hh:mm-hh:mm format."
  }
}

variable "rds_preferred_maintenance_window" {
  description = "Preferred UTC maintenance window for PostgreSQL, such as sun:04:00-sun:05:00."
  type        = string
  default     = "sun:04:00-sun:05:00"

  validation {
    condition     = can(regex("^(mon|tue|wed|thu|fri|sat|sun):[0-2][0-9]:[0-5][0-9]-(mon|tue|wed|thu|fri|sat|sun):[0-2][0-9]:[0-5][0-9]$", var.rds_preferred_maintenance_window))
    error_message = "rds_preferred_maintenance_window must use ddd:hh:mm-ddd:hh:mm format with lowercase day names."
  }
}

variable "rds_deletion_protection_enabled" {
  description = "Whether PostgreSQL deletion protection is enabled. Prod enables this to show production-intent safeguards."
  type        = bool
  default     = true
}

variable "rds_skip_final_snapshot" {
  description = "Whether to skip a final PostgreSQL snapshot during a user-owned destroy."
  type        = bool
  default     = false
}

variable "rds_final_snapshot_identifier" {
  description = "Optional final snapshot identifier when rds_skip_final_snapshot is false. Defaults inside the module when null."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = var.rds_final_snapshot_identifier == null ? true : can(regex("^[a-z][a-z0-9-]+$", var.rds_final_snapshot_identifier))
    error_message = "rds_final_snapshot_identifier must be lowercase kebab-case when provided."
  }
}

variable "rds_delete_automated_backups" {
  description = "Whether automated PostgreSQL backups are deleted with the instance during a user-owned destroy."
  type        = bool
  default     = false
}

variable "rds_copy_tags_to_snapshot" {
  description = "Whether PostgreSQL tags are copied to snapshots for reviewability and cleanup."
  type        = bool
  default     = true
}

variable "rds_auto_minor_version_upgrade" {
  description = "Whether RDS may apply PostgreSQL minor version upgrades during maintenance windows."
  type        = bool
  default     = true
}

variable "rds_apply_immediately" {
  description = "Whether PostgreSQL changes apply immediately instead of during the maintenance window. Keep false for reviewable operations."
  type        = bool
  default     = false
}

variable "rds_enabled_cloudwatch_logs_exports" {
  description = "PostgreSQL log exports to CloudWatch Logs. Values are log type references, not log contents."
  type        = list(string)
  default     = ["postgresql", "upgrade"]

  validation {
    condition     = alltrue([for log_type in var.rds_enabled_cloudwatch_logs_exports : contains(["postgresql", "upgrade"], log_type)])
    error_message = "rds_enabled_cloudwatch_logs_exports may only contain postgresql and upgrade."
  }
}

variable "rds_monitoring_interval" {
  description = "Enhanced monitoring interval in seconds. Keep 0 unless a reviewed monitoring role ARN is supplied."
  type        = number
  default     = 0

  validation {
    condition     = contains([0, 1, 5, 10, 15, 30, 60], var.rds_monitoring_interval)
    error_message = "rds_monitoring_interval must be one of 0, 1, 5, 10, 15, 30, or 60."
  }
}

variable "rds_monitoring_role_arn" {
  description = "IAM role ARN for RDS enhanced monitoring. Keep null in committed examples."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition = var.rds_monitoring_role_arn == null ? true : can(regex(
      "^arn:aws[a-zA-Z-]*:iam::[0-9]{12}:role/.+",
      var.rds_monitoring_role_arn
    ))
    error_message = "rds_monitoring_role_arn must be an IAM role ARN when provided."
  }
}

variable "rds_performance_insights_enabled" {
  description = "Whether RDS Performance Insights/Database Insights is enabled for PostgreSQL."
  type        = bool
  default     = true
}

variable "rds_performance_insights_retention_period" {
  description = "Performance Insights retention period. AWS supports 7, 731, or month-sized multiples of 31 days."
  type        = number
  default     = 7

  validation {
    condition     = contains(concat([7, 731], [for month in range(1, 24) : month * 31]), var.rds_performance_insights_retention_period)
    error_message = "rds_performance_insights_retention_period must be 7, 731, or a multiple of 31 from 31 through 713."
  }
}

variable "rds_performance_insights_kms_key_id" {
  description = "Optional KMS key ID/ARN for RDS Performance Insights. Keep null in committed examples."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = var.rds_performance_insights_kms_key_id == null ? true : length(trimspace(var.rds_performance_insights_kms_key_id)) > 0
    error_message = "rds_performance_insights_kms_key_id must be null or a non-empty KMS key identifier."
  }
}

variable "rds_ca_cert_identifier" {
  description = "Optional RDS CA certificate identifier. Keep null unless a user-owned environment has reviewed certificate rotation."
  type        = string
  default     = null
  nullable    = true
}

variable "redis_port" {
  description = "Redis/Valkey port allowed from private ECS services to the private cache security group when Redis is enabled."
  type        = number
  default     = 6379

  validation {
    condition     = var.redis_port >= 1 && var.redis_port <= 65535
    error_message = "redis_port must be a valid TCP port."
  }
}

variable "redis_engine" {
  description = "ElastiCache engine for the optional prod cache. Use redis or valkey where supported."
  type        = string
  default     = "redis"

  validation {
    condition     = contains(["redis", "valkey"], var.redis_engine)
    error_message = "redis_engine must be redis or valkey."
  }
}

variable "redis_engine_version" {
  description = "Redis/Valkey engine version for the optional prod cache. Review regional support before manual provisioning."
  type        = string
  default     = "7.1"

  validation {
    condition     = length(trimspace(var.redis_engine_version)) > 0
    error_message = "redis_engine_version must not be empty."
  }
}

variable "redis_node_type" {
  description = "ElastiCache node type for the optional prod cache. Review against workload and cost needs before provisioning."
  type        = string
  default     = "cache.t4g.small"

  validation {
    condition     = startswith(var.redis_node_type, "cache.")
    error_message = "redis_node_type must look like an ElastiCache node type such as cache.t4g.small."
  }
}

variable "redis_parameter_group_name" {
  description = "Optional Redis/Valkey parameter group name. Keep null to use the AWS default for the selected engine/version."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = var.redis_parameter_group_name == null ? true : length(trimspace(var.redis_parameter_group_name)) > 0
    error_message = "redis_parameter_group_name must be null or non-empty."
  }
}

variable "redis_replica_count" {
  description = "Number of Redis/Valkey read replicas. Prod defaults to one to show failover/Multi-AZ intent."
  type        = number
  default     = 1

  validation {
    condition     = var.redis_replica_count >= 0 && var.redis_replica_count <= 5
    error_message = "redis_replica_count must be between 0 and 5."
  }
}

variable "redis_automatic_failover_enabled" {
  description = "Whether ElastiCache can promote a Redis/Valkey replica if the primary fails. Requires at least one replica."
  type        = bool
  default     = true
}

variable "redis_multi_az_enabled" {
  description = "Whether Multi-AZ support is enabled for the optional cache. Requires at least one replica."
  type        = bool
  default     = true
}

variable "redis_at_rest_encryption_enabled" {
  description = "Whether cache at-rest encryption is enabled. Keep true unless a reviewed exception exists."
  type        = bool
  default     = true
}

variable "redis_transit_encryption_enabled" {
  description = "Whether in-transit encryption is enabled for cache client traffic."
  type        = bool
  default     = true
}

variable "redis_kms_key_id" {
  description = "Optional user-owned KMS key ID/ARN for cache at-rest encryption. Keep null in committed examples."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = var.redis_kms_key_id == null ? true : length(trimspace(var.redis_kms_key_id)) > 0
    error_message = "redis_kms_key_id must be null or a non-empty KMS key identifier."
  }
}

variable "redis_snapshot_retention_days" {
  description = "Number of days to retain automatic cache snapshots. Prod uses a non-zero value to show production intent."
  type        = number
  default     = 7

  validation {
    condition     = var.redis_snapshot_retention_days >= 0 && var.redis_snapshot_retention_days <= 35
    error_message = "redis_snapshot_retention_days must be between 0 and 35."
  }
}

variable "redis_snapshot_window" {
  description = "Optional UTC snapshot window in hh:mm-hh:mm format."
  type        = string
  default     = "04:00-05:00"
  nullable    = true

  validation {
    condition     = var.redis_snapshot_window == null ? true : can(regex("^[0-2][0-9]:[0-5][0-9]-[0-2][0-9]:[0-5][0-9]$", var.redis_snapshot_window))
    error_message = "redis_snapshot_window must be null or use hh:mm-hh:mm format."
  }
}

variable "redis_final_snapshot_identifier" {
  description = "Optional final cache snapshot identifier for user-owned deletion."
  type        = string
  default     = "platform-infra-lab-prod-redis-final"
  nullable    = true

  validation {
    condition     = var.redis_final_snapshot_identifier == null ? true : can(regex("^[a-z][a-z0-9-]+$", var.redis_final_snapshot_identifier))
    error_message = "redis_final_snapshot_identifier must be lowercase kebab-case when provided."
  }
}

variable "redis_maintenance_window" {
  description = "Preferred UTC maintenance window for the optional cache, such as sun:05:00-sun:06:00."
  type        = string
  default     = "sun:05:00-sun:06:00"

  validation {
    condition     = can(regex("^(mon|tue|wed|thu|fri|sat|sun):[0-2][0-9]:[0-5][0-9]-(mon|tue|wed|thu|fri|sat|sun):[0-2][0-9]:[0-5][0-9]$", var.redis_maintenance_window))
    error_message = "redis_maintenance_window must use ddd:hh:mm-ddd:hh:mm format with lowercase day names."
  }
}

variable "redis_apply_immediately" {
  description = "Whether cache changes apply immediately instead of during the maintenance window. Keep false for reviewable operations."
  type        = bool
  default     = false
}

variable "redis_auto_minor_version_upgrade" {
  description = "Whether ElastiCache may apply supported minor engine upgrades during maintenance windows."
  type        = bool
  default     = true
}

variable "execution_secret_reference_arns" {
  description = "Public-safe placeholder Secrets Manager ARNs that the ECS task execution role may read for task-definition secret injection. References only; no secret values."
  type        = list(string)
  default = [
    "arn:aws:secretsmanager:us-east-1:123456789012:secret:platform-infra-lab/prod/ecs-execution/*",
  ]
}

variable "execution_ssm_parameter_arns" {
  description = "Public-safe placeholder SSM Parameter Store ARNs that the ECS task execution role may read for task-definition secret injection. References only; no parameter values."
  type        = list(string)
  default = [
    "arn:aws:ssm:us-east-1:123456789012:parameter/platform-infra-lab/prod/ecs-execution/*",
  ]
}

variable "execution_kms_key_arns" {
  description = "Optional placeholder KMS key ARNs for execution-role decrypt access when secret references use customer-managed keys. Empty by default."
  type        = list(string)
  default     = []
}

variable "task_secret_reference_arns" {
  description = "Public-safe placeholder Secrets Manager ARNs that application code may read through the ECS task role. References only; no secret values."
  type        = list(string)
  default = [
    "arn:aws:secretsmanager:us-east-1:123456789012:secret:platform-infra-lab/prod/application/*",
  ]
}

variable "task_ssm_parameter_arns" {
  description = "Public-safe placeholder SSM Parameter Store ARNs that application code may read through the ECS task role. References only; no parameter values."
  type        = list(string)
  default = [
    "arn:aws:ssm:us-east-1:123456789012:parameter/platform-infra-lab/prod/application/*",
  ]
}

variable "task_kms_key_arns" {
  description = "Optional placeholder KMS key ARNs for application task-role decrypt access when secret references use customer-managed keys. Empty by default."
  type        = list(string)
  default     = []
}
