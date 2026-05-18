variable "name_prefix" {
  description = "Public-safe prefix used for network resource names."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]+$", var.name_prefix))
    error_message = "name_prefix must be lowercase kebab-case."
  }
}

variable "environment" {
  description = "Environment name used for documentation and tagging context."
  type        = string

  validation {
    condition     = length(trimspace(var.environment)) > 0
    error_message = "environment must not be empty."
  }
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "vpc_cidr must be a valid CIDR block."
  }
}

variable "availability_zones" {
  description = "Availability zones used for subnet placement. Provide at least as many entries as public/private subnet CIDR entries."
  type        = list(string)

  validation {
    condition     = length(var.availability_zones) >= 2 && alltrue([for zone in var.availability_zones : length(trimspace(zone)) > 0])
    error_message = "availability_zones must include at least two non-empty zone names."
  }
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets intended for internet-facing load balancers and NAT gateways."
  type        = list(string)

  validation {
    condition     = length(var.public_subnet_cidrs) >= 2 && alltrue([for cidr in var.public_subnet_cidrs : can(cidrnetmask(cidr))])
    error_message = "public_subnet_cidrs must contain at least two valid CIDR blocks."
  }
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets intended for ECS services, databases, and caches."
  type        = list(string)

  validation {
    condition     = length(var.private_subnet_cidrs) >= 2 && alltrue([for cidr in var.private_subnet_cidrs : can(cidrnetmask(cidr))])
    error_message = "private_subnet_cidrs must contain at least two valid CIDR blocks."
  }
}

variable "enable_nat_gateway" {
  description = "Whether to create one NAT gateway for private subnet egress. This can add ongoing cloud cost if provisioned."
  type        = bool
  default     = false
}

variable "enable_dns_hostnames" {
  description = "Whether the VPC should assign DNS hostnames for resources that support them."
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Whether the VPC should enable DNS resolution support."
  type        = bool
  default     = true
}

variable "common_tags" {
  description = "Common public-safe tags applied to taggable network resources."
  type        = map(string)
  default     = {}
}
