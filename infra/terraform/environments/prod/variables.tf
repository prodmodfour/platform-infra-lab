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
  description = "CIDR block reserved for the future prod VPC."
  type        = string
  default     = "10.30.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "vpc_cidr must be a valid CIDR block."
  }
}

variable "availability_zones" {
  description = "Availability zone names used by future subnet modules."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]

  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "At least two availability zones should be shown for the platform pattern."
  }
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks reserved for future public subnets such as the ALB edge."
  type        = list(string)
  default     = ["10.30.0.0/24", "10.30.1.0/24", "10.30.2.0/24"]

  validation {
    condition     = length(var.public_subnet_cidrs) >= 2 && alltrue([for cidr in var.public_subnet_cidrs : can(cidrnetmask(cidr))])
    error_message = "public_subnet_cidrs must contain at least two valid CIDR blocks."
  }
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks reserved for future private ECS, database, and cache subnets."
  type        = list(string)
  default     = ["10.30.10.0/24", "10.30.11.0/24", "10.30.12.0/24"]

  validation {
    condition     = length(var.private_subnet_cidrs) >= 2 && alltrue([for cidr in var.private_subnet_cidrs : can(cidrnetmask(cidr))])
    error_message = "private_subnet_cidrs must contain at least two valid CIDR blocks."
  }
}

variable "enable_nat_gateway" {
  description = "Future network module flag. Prod shows production intent with NAT enabled for private egress review."
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
  description = "Default desired task count for future prod ECS service examples."
  type        = number
  default     = 2

  validation {
    condition     = var.service_desired_count_default >= 1
    error_message = "service_desired_count_default must be at least 1."
  }
}
