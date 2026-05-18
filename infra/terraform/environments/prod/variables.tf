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
  description = "CIDR blocks for public subnets such as the future ALB edge."
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
  description = "Future Redis/ElastiCache module flag. Prod example enables the optional cache tier for review."
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
  description = "Whether ECS service modules should create ALB listener rules. Prod keeps this false until the load-balancer module provides a listener ARN."
  type        = bool
  default     = false
}

variable "ecs_listener_arn" {
  description = "Optional ALB listener ARN used when create_ecs_listener_rules is true. Keep placeholder-only in committed examples."
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
  description = "IPv4 CIDR blocks allowed to reach the future public ALB. Prod keeps the edge public in this placeholder but production should review WAF/trusted CIDR restrictions."
  type        = list(string)
  default     = ["0.0.0.0/0"]

  validation {
    condition     = length(var.alb_ingress_cidrs) > 0 && alltrue([for cidr in var.alb_ingress_cidrs : can(cidrnetmask(cidr))])
    error_message = "alb_ingress_cidrs must contain at least one valid IPv4 CIDR block."
  }
}

variable "alb_ingress_ports" {
  description = "TCP ports exposed on the future public ALB security group. Prod includes HTTP now; HTTPS is documented for later load-balancer work."
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

variable "redis_port" {
  description = "Redis/Valkey port allowed from private ECS services to the private cache security group when Redis is enabled."
  type        = number
  default     = 6379

  validation {
    condition     = var.redis_port >= 1 && var.redis_port <= 65535
    error_message = "redis_port must be a valid TCP port."
  }
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
