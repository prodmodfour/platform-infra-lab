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
  default     = "dev"

  validation {
    condition     = var.environment_name == "dev"
    error_message = "The dev environment root must use environment_name = \"dev\"."
  }
}

variable "additional_tags" {
  description = "Additional public-safe tags merged with the common tag set. Do not include secrets, private names, or account IDs."
  type        = map(string)
  default     = {}
}

variable "vpc_cidr" {
  description = "CIDR block for the dev VPC."
  type        = string
  default     = "10.20.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "vpc_cidr must be a valid CIDR block."
  }
}

variable "availability_zones" {
  description = "Availability zone names used by the network module for subnet placement."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]

  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "At least two availability zones should be shown for the platform pattern."
  }
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets such as the future ALB edge."
  type        = list(string)
  default     = ["10.20.0.0/24", "10.20.1.0/24"]

  validation {
    condition     = length(var.public_subnet_cidrs) >= 2 && alltrue([for cidr in var.public_subnet_cidrs : can(cidrnetmask(cidr))])
    error_message = "public_subnet_cidrs must contain at least two valid CIDR blocks."
  }
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private ECS, database, and cache subnet placement."
  type        = list(string)
  default     = ["10.20.10.0/24", "10.20.11.0/24"]

  validation {
    condition     = length(var.private_subnet_cidrs) >= 2 && alltrue([for cidr in var.private_subnet_cidrs : can(cidrnetmask(cidr))])
    error_message = "private_subnet_cidrs must contain at least two valid CIDR blocks."
  }
}

variable "enable_nat_gateway" {
  description = "Network module flag. Dev defaults to false to keep the lab cost-aware unless private egress is explicitly needed."
  type        = bool
  default     = false
}

variable "log_retention_days" {
  description = "Default CloudWatch log retention days for future dev service log groups."
  type        = number
  default     = 7

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3653], var.log_retention_days)
    error_message = "log_retention_days must match a CloudWatch Logs retention option."
  }
}

variable "deletion_protection_enabled" {
  description = "Future stateful-service deletion protection default. Dev keeps this false for disposable lab environments."
  type        = bool
  default     = false
}

variable "enable_redis" {
  description = "Future Redis/ElastiCache module flag. Dev keeps this disabled by default to avoid unnecessary lab cost."
  type        = bool
  default     = false
}

variable "service_desired_count_default" {
  description = "Default desired task count for future dev ECS service examples."
  type        = number
  default     = 1

  validation {
    condition     = var.service_desired_count_default >= 1
    error_message = "service_desired_count_default must be at least 1."
  }
}

variable "alb_ingress_cidrs" {
  description = "IPv4 CIDR blocks allowed to reach the future public ALB. Dev uses public internet in the example so the ALB is the only public ingress boundary."
  type        = list(string)
  default     = ["0.0.0.0/0"]

  validation {
    condition     = length(var.alb_ingress_cidrs) > 0 && alltrue([for cidr in var.alb_ingress_cidrs : can(cidrnetmask(cidr))])
    error_message = "alb_ingress_cidrs must contain at least one valid IPv4 CIDR block."
  }
}

variable "alb_ingress_ports" {
  description = "TCP ports exposed on the future public ALB security group. Dev defaults to HTTP only for the placeholder edge."
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
