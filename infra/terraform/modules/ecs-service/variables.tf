variable "name_prefix" {
  description = "Public-safe prefix used for ECS service names, task families, and log groups."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]+$", var.name_prefix)) && length(var.name_prefix) <= 40
    error_message = "name_prefix must be lowercase kebab-case and no more than 40 characters."
  }
}

variable "environment" {
  description = "Environment name used for tags and short target group names."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]+$", var.environment)) && length(var.environment) <= 8
    error_message = "environment must be short lowercase kebab-case."
  }
}

variable "service_name" {
  description = "Public-safe service identifier, such as carbon-platform-api."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]+$", var.service_name)) && length(var.service_name) <= 24
    error_message = "service_name must be lowercase kebab-case and no more than 24 characters."
  }
}

variable "aws_region" {
  description = "AWS region used in container awslogs configuration."
  type        = string

  validation {
    condition     = length(trimspace(var.aws_region)) > 0
    error_message = "aws_region must not be empty."
  }
}

variable "vpc_id" {
  description = "VPC ID for the ALB target group."
  type        = string
}

variable "cluster_arn" {
  description = "ARN or ID of the ECS cluster that runs this service."
  type        = string

  validation {
    condition     = length(trimspace(var.cluster_arn)) > 0
    error_message = "cluster_arn must not be empty."
  }
}

variable "cluster_name" {
  description = "ECS cluster name used by Application Auto Scaling resource IDs."
  type        = string

  validation {
    condition     = length(trimspace(var.cluster_name)) > 0
    error_message = "cluster_name must not be empty."
  }
}

variable "private_subnet_ids" {
  description = "Private subnet IDs used by Fargate task ENIs."
  type        = list(string)

  validation {
    condition     = length(var.private_subnet_ids) >= 2
    error_message = "private_subnet_ids must contain at least two subnet IDs for the platform pattern."
  }
}

variable "security_group_ids" {
  description = "Security group IDs attached to Fargate task ENIs. Pass the private ECS service security group from the security-groups module."
  type        = list(string)

  validation {
    condition     = length(var.security_group_ids) > 0
    error_message = "security_group_ids must contain at least one security group ID."
  }
}

variable "task_execution_role_arn" {
  description = "ECS task execution role ARN used for image pulls, log delivery, and ECS-managed secret injection."
  type        = string

  validation {
    condition     = can(regex("^arn:aws[a-zA-Z-]*:iam::[0-9]{12}:role/.+", var.task_execution_role_arn))
    error_message = "task_execution_role_arn must be an IAM role ARN."
  }
}

variable "task_role_arn" {
  description = "Application ECS task role ARN. Keep application AWS permissions separate from the execution role."
  type        = string

  validation {
    condition     = can(regex("^arn:aws[a-zA-Z-]*:iam::[0-9]{12}:role/.+", var.task_role_arn))
    error_message = "task_role_arn must be an IAM role ARN."
  }
}

variable "container_image" {
  description = "Fake public demo image URI for the service. Do not use private or employer images in this portfolio repo."
  type        = string

  validation {
    condition     = can(regex("^public\\.ecr\\.aws/example/[a-z0-9-]+:demo$", var.container_image))
    error_message = "container_image must be a public-safe fake image like public.ecr.aws/example/carbon-platform-api:demo."
  }
}

variable "container_port" {
  description = "Container port exposed to the target group and allowed by the ECS service security group."
  type        = number
  default     = 8080

  validation {
    condition     = var.container_port >= 1 && var.container_port <= 65535
    error_message = "container_port must be a valid TCP port."
  }
}

variable "cpu" {
  description = "Fargate task CPU units."
  type        = number
  default     = 256

  validation {
    condition     = contains([256, 512, 1024, 2048, 4096], var.cpu)
    error_message = "cpu must be one of the common Fargate CPU unit values: 256, 512, 1024, 2048, or 4096."
  }
}

variable "memory" {
  description = "Fargate task memory in MiB."
  type        = number
  default     = 512

  validation {
    condition     = var.memory >= 512 && var.memory <= 30720
    error_message = "memory must be between 512 and 30720 MiB."
  }
}

variable "desired_count" {
  description = "Initial desired task count for the ECS service."
  type        = number
  default     = 1

  validation {
    condition     = var.desired_count >= 1
    error_message = "desired_count must be at least 1."
  }
}

variable "environment_variables" {
  description = "Non-secret container environment variables. Secret values must use secret_references instead."
  type        = map(string)
  default     = {}

  validation {
    condition     = alltrue([for name in keys(var.environment_variables) : can(regex("^[A-Z_][A-Z0-9_]*$", name))])
    error_message = "environment variable names must be uppercase shell-style identifiers."
  }
}

variable "secret_references" {
  description = "Container secret references as ENV_VAR_NAME => Secrets Manager or SSM Parameter Store ARN. Values are references only, not secret values."
  type        = map(string)
  default     = {}

  validation {
    condition = alltrue([
      for name in keys(var.secret_references) : can(regex("^[A-Z_][A-Z0-9_]*$", name))
    ])
    error_message = "secret reference names must be uppercase shell-style identifiers."
  }

  validation {
    condition = alltrue([
      for arn in values(var.secret_references) :
      can(regex("^arn:aws[a-zA-Z-]*:secretsmanager:[a-z0-9-]+:[0-9]{12}:secret:.+", arn)) ||
      can(regex("^arn:aws[a-zA-Z-]*:ssm:[a-z0-9-]+:[0-9]{12}:parameter/.+", arn))
    ])
    error_message = "secret_references values must be Secrets Manager or SSM Parameter Store ARNs, not secret values."
  }
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention period for the service log group."
  type        = number
  default     = 7

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3653], var.log_retention_days)
    error_message = "log_retention_days must match a CloudWatch Logs retention option."
  }
}

variable "assign_public_ip" {
  description = "Whether Fargate tasks receive public IPs. Keep false for private service placement."
  type        = bool
  default     = false
}

variable "readonly_root_filesystem" {
  description = "Whether the container root filesystem should be read-only. Real applications may need writable tmp paths."
  type        = bool
  default     = true
}

variable "target_group_protocol" {
  description = "Protocol used by the target group to reach the container."
  type        = string
  default     = "HTTP"

  validation {
    condition     = contains(["HTTP", "HTTPS"], var.target_group_protocol)
    error_message = "target_group_protocol must be HTTP or HTTPS."
  }
}

variable "deregistration_delay_seconds" {
  description = "Target group deregistration delay in seconds for connection draining."
  type        = number
  default     = 30

  validation {
    condition     = var.deregistration_delay_seconds >= 0 && var.deregistration_delay_seconds <= 3600
    error_message = "deregistration_delay_seconds must be between 0 and 3600."
  }
}

variable "health_check_path" {
  description = "HTTP health check path used by the target group and default container health check command."
  type        = string
  default     = "/health"

  validation {
    condition     = startswith(var.health_check_path, "/")
    error_message = "health_check_path must start with /."
  }
}

variable "health_check_protocol" {
  description = "Protocol used by the target group health check."
  type        = string
  default     = "HTTP"

  validation {
    condition     = contains(["HTTP", "HTTPS"], var.health_check_protocol)
    error_message = "health_check_protocol must be HTTP or HTTPS."
  }
}

variable "health_check_matcher" {
  description = "HTTP status code matcher for the target group health check."
  type        = string
  default     = "200-399"
}

variable "health_check_interval" {
  description = "Target group health check interval in seconds."
  type        = number
  default     = 30

  validation {
    condition     = var.health_check_interval >= 5 && var.health_check_interval <= 300
    error_message = "health_check_interval must be between 5 and 300 seconds."
  }
}

variable "health_check_timeout" {
  description = "Target group health check timeout in seconds."
  type        = number
  default     = 5

  validation {
    condition     = var.health_check_timeout >= 2 && var.health_check_timeout <= 120
    error_message = "health_check_timeout must be between 2 and 120 seconds."
  }
}

variable "healthy_threshold" {
  description = "Number of successful target group checks before a target is healthy."
  type        = number
  default     = 2

  validation {
    condition     = var.healthy_threshold >= 2 && var.healthy_threshold <= 10
    error_message = "healthy_threshold must be between 2 and 10."
  }
}

variable "unhealthy_threshold" {
  description = "Number of failed target group checks before a target is unhealthy."
  type        = number
  default     = 3

  validation {
    condition     = var.unhealthy_threshold >= 2 && var.unhealthy_threshold <= 10
    error_message = "unhealthy_threshold must be between 2 and 10."
  }
}

variable "container_health_check_command" {
  description = "Optional ECS container health check command. When empty, the module builds a curl command from container_port and health_check_path."
  type        = list(string)
  default     = []
}

variable "container_health_check_interval" {
  description = "ECS container health check interval in seconds."
  type        = number
  default     = 30

  validation {
    condition     = var.container_health_check_interval >= 5 && var.container_health_check_interval <= 300
    error_message = "container_health_check_interval must be between 5 and 300 seconds."
  }
}

variable "container_health_check_timeout" {
  description = "ECS container health check timeout in seconds."
  type        = number
  default     = 5

  validation {
    condition     = var.container_health_check_timeout >= 2 && var.container_health_check_timeout <= 60
    error_message = "container_health_check_timeout must be between 2 and 60 seconds."
  }
}

variable "container_health_check_retries" {
  description = "ECS container health check retries before marking the container unhealthy."
  type        = number
  default     = 3

  validation {
    condition     = var.container_health_check_retries >= 1 && var.container_health_check_retries <= 10
    error_message = "container_health_check_retries must be between 1 and 10."
  }
}

variable "container_health_check_start_period" {
  description = "ECS container health check start period in seconds."
  type        = number
  default     = 30

  validation {
    condition     = var.container_health_check_start_period >= 0 && var.container_health_check_start_period <= 300
    error_message = "container_health_check_start_period must be between 0 and 300 seconds."
  }
}

variable "create_listener_rule" {
  description = "Whether to create an ALB listener rule that forwards matching paths to this service target group. Disabled until the load-balancer module wires a listener."
  type        = bool
  default     = false
}

variable "listener_arn" {
  description = "ALB listener ARN used when create_listener_rule is true. Use a placeholder in examples only; no real account IDs in committed files."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition = var.listener_arn == null ? true : can(regex(
      "^arn:aws[a-zA-Z-]*:elasticloadbalancing:[a-z0-9-]+:[0-9]{12}:listener/app/.+",
      var.listener_arn
    ))
    error_message = "listener_arn must be an ALB listener ARN when provided."
  }
}

variable "listener_rule_priority" {
  description = "ALB listener rule priority used when create_listener_rule is true."
  type        = number
  default     = null
  nullable    = true

  validation {
    condition     = var.listener_rule_priority == null ? true : var.listener_rule_priority >= 1 && var.listener_rule_priority <= 50000
    error_message = "listener_rule_priority must be between 1 and 50000 when provided."
  }
}

variable "listener_rule_path_patterns" {
  description = "ALB path patterns for the optional listener rule. Defaults to /<service_name>* when empty."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for pattern in var.listener_rule_path_patterns : startswith(pattern, "/")])
    error_message = "listener_rule_path_patterns must start with /."
  }
}

variable "deployment_minimum_healthy_percent" {
  description = "Minimum healthy percent for rolling ECS deployments."
  type        = number
  default     = 50

  validation {
    condition     = var.deployment_minimum_healthy_percent >= 0 && var.deployment_minimum_healthy_percent <= 100
    error_message = "deployment_minimum_healthy_percent must be between 0 and 100."
  }
}

variable "deployment_maximum_percent" {
  description = "Maximum percent for rolling ECS deployments."
  type        = number
  default     = 200

  validation {
    condition     = var.deployment_maximum_percent >= 100 && var.deployment_maximum_percent <= 300
    error_message = "deployment_maximum_percent must be between 100 and 300."
  }
}

variable "deployment_circuit_breaker_enabled" {
  description = "Whether to enable the ECS deployment circuit breaker."
  type        = bool
  default     = true
}

variable "deployment_circuit_breaker_rollback" {
  description = "Whether ECS should roll back automatically when the deployment circuit breaker trips."
  type        = bool
  default     = true
}

variable "health_check_grace_period_seconds" {
  description = "ECS service health check grace period after task start."
  type        = number
  default     = 60

  validation {
    condition     = var.health_check_grace_period_seconds >= 0 && var.health_check_grace_period_seconds <= 7200
    error_message = "health_check_grace_period_seconds must be between 0 and 7200."
  }
}

variable "enable_execute_command" {
  description = "Whether ECS Exec is enabled. Disabled by default because real use requires reviewed IAM, logging, and access controls."
  type        = bool
  default     = false
}

variable "platform_version" {
  description = "Fargate platform version."
  type        = string
  default     = "LATEST"
}

variable "operating_system_family" {
  description = "ECS task runtime operating system family."
  type        = string
  default     = "LINUX"

  validation {
    condition     = contains(["LINUX"], var.operating_system_family)
    error_message = "This public example currently models LINUX Fargate tasks only."
  }
}

variable "cpu_architecture" {
  description = "ECS task CPU architecture."
  type        = string
  default     = "X86_64"

  validation {
    condition     = contains(["X86_64", "ARM64"], var.cpu_architecture)
    error_message = "cpu_architecture must be X86_64 or ARM64."
  }
}

variable "enable_autoscaling" {
  description = "Whether to create target-tracking Application Auto Scaling resources for desired count."
  type        = bool
  default     = true
}

variable "autoscaling_min_capacity" {
  description = "Minimum task count for ECS service autoscaling."
  type        = number
  default     = 1

  validation {
    condition     = var.autoscaling_min_capacity >= 1
    error_message = "autoscaling_min_capacity must be at least 1."
  }
}

variable "autoscaling_max_capacity" {
  description = "Maximum task count for ECS service autoscaling."
  type        = number
  default     = 2

  validation {
    condition     = var.autoscaling_max_capacity >= 1
    error_message = "autoscaling_max_capacity must be at least 1."
  }
}

variable "autoscaling_cpu_target_value" {
  description = "Target average CPU utilization percentage for ECS service autoscaling."
  type        = number
  default     = 60

  validation {
    condition     = var.autoscaling_cpu_target_value > 0 && var.autoscaling_cpu_target_value <= 100
    error_message = "autoscaling_cpu_target_value must be between 1 and 100."
  }
}

variable "autoscaling_memory_target_value" {
  description = "Target average memory utilization percentage for ECS service autoscaling."
  type        = number
  default     = 70

  validation {
    condition     = var.autoscaling_memory_target_value > 0 && var.autoscaling_memory_target_value <= 100
    error_message = "autoscaling_memory_target_value must be between 1 and 100."
  }
}

variable "autoscaling_scale_in_cooldown" {
  description = "Scale-in cooldown in seconds for target tracking policies."
  type        = number
  default     = 300

  validation {
    condition     = var.autoscaling_scale_in_cooldown >= 0
    error_message = "autoscaling_scale_in_cooldown must be non-negative."
  }
}

variable "autoscaling_scale_out_cooldown" {
  description = "Scale-out cooldown in seconds for target tracking policies."
  type        = number
  default     = 60

  validation {
    condition     = var.autoscaling_scale_out_cooldown >= 0
    error_message = "autoscaling_scale_out_cooldown must be non-negative."
  }
}

variable "common_tags" {
  description = "Common public-safe tags applied to taggable ECS service resources."
  type        = map(string)
  default     = {}
}
