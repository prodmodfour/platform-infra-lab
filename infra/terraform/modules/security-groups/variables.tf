variable "name_prefix" {
  description = "Public-safe prefix used for security group names."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]+$", var.name_prefix))
    error_message = "name_prefix must be lowercase kebab-case."
  }
}

variable "environment" {
  description = "Environment name used for tags and documentation context."
  type        = string

  validation {
    condition     = length(trimspace(var.environment)) > 0
    error_message = "environment must not be empty."
  }
}

variable "vpc_id" {
  description = "ID of the VPC where the security groups are created."
  type        = string
}

variable "alb_ingress_cidrs" {
  description = "IPv4 CIDR blocks allowed to reach the public Application Load Balancer. Defaults to the public internet for the demo edge only."
  type        = list(string)
  default     = ["0.0.0.0/0"]

  validation {
    condition     = length(var.alb_ingress_cidrs) > 0 && alltrue([for cidr in var.alb_ingress_cidrs : can(cidrnetmask(cidr))])
    error_message = "alb_ingress_cidrs must contain at least one valid IPv4 CIDR block."
  }
}

variable "alb_ingress_ports" {
  description = "TCP ports exposed on the public ALB security group. Keep this narrow; HTTPS should be reviewed with a real certificate outside this public example."
  type        = list(number)
  default     = [80]

  validation {
    condition     = length(var.alb_ingress_ports) > 0 && alltrue([for port in var.alb_ingress_ports : port >= 1 && port <= 65535])
    error_message = "alb_ingress_ports must contain valid TCP port numbers."
  }
}

variable "service_port" {
  description = "Application port that the ALB may use to reach ECS service tasks."
  type        = number
  default     = 8080

  validation {
    condition     = var.service_port >= 1 && var.service_port <= 65535
    error_message = "service_port must be a valid TCP port."
  }
}

variable "database_port" {
  description = "PostgreSQL port allowed from ECS services to the private database security group."
  type        = number
  default     = 5432

  validation {
    condition     = var.database_port >= 1 && var.database_port <= 65535
    error_message = "database_port must be a valid TCP port."
  }
}

variable "enable_redis" {
  description = "Whether to create the Redis cache security group and ECS-to-Redis rules."
  type        = bool
  default     = false
}

variable "redis_port" {
  description = "Redis/Valkey port allowed from ECS services to the private cache security group when enable_redis is true."
  type        = number
  default     = 6379

  validation {
    condition     = var.redis_port >= 1 && var.redis_port <= 65535
    error_message = "redis_port must be a valid TCP port."
  }
}

variable "common_tags" {
  description = "Common public-safe tags applied to taggable security group resources."
  type        = map(string)
  default     = {}
}
