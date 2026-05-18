variable "name_prefix" {
  description = "Public-safe prefix used for the Application Load Balancer name."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]+$", var.name_prefix)) && length(var.name_prefix) <= 28
    error_message = "name_prefix must be lowercase kebab-case and no more than 28 characters so the ALB name stays within AWS limits."
  }
}

variable "environment" {
  description = "Environment name used for tags and review summaries."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]+$", var.environment)) && length(var.environment) <= 8
    error_message = "environment must be short lowercase kebab-case."
  }
}

variable "public_subnet_ids" {
  description = "Public subnet IDs where the internet-facing Application Load Balancer is placed."
  type        = list(string)

  validation {
    condition     = length(var.public_subnet_ids) >= 2
    error_message = "public_subnet_ids must include at least two subnets for the ALB pattern."
  }
}

variable "security_group_ids" {
  description = "Security group IDs attached to the ALB, normally the load balancer security group from the security-groups module."
  type        = list(string)

  validation {
    condition     = length(var.security_group_ids) > 0
    error_message = "security_group_ids must include at least one security group ID."
  }
}

variable "internal" {
  description = "Whether the ALB is internal. The portfolio default is false because this module models the public edge."
  type        = bool
  default     = false
}

variable "enable_deletion_protection" {
  description = "Whether to enable ALB deletion protection. This can be useful for production intent but complicates cleanup."
  type        = bool
  default     = false
}

variable "drop_invalid_header_fields" {
  description = "Whether the ALB should drop invalid HTTP header fields. Enabled by default as a safe edge posture."
  type        = bool
  default     = true
}

variable "enable_http2" {
  description = "Whether HTTP/2 is enabled on the ALB."
  type        = bool
  default     = true
}

variable "idle_timeout_seconds" {
  description = "ALB idle timeout in seconds."
  type        = number
  default     = 60

  validation {
    condition     = var.idle_timeout_seconds >= 1 && var.idle_timeout_seconds <= 4000
    error_message = "idle_timeout_seconds must be between 1 and 4000."
  }
}

variable "http_listener_port" {
  description = "Port for the required HTTP listener."
  type        = number
  default     = 80

  validation {
    condition     = var.http_listener_port >= 1 && var.http_listener_port <= 65535
    error_message = "http_listener_port must be a valid TCP port."
  }
}

variable "enable_https_listener" {
  description = "Whether to create an optional HTTPS listener. No real certificate ARN is committed by this repo."
  type        = bool
  default     = false
}

variable "https_listener_port" {
  description = "Port for the optional HTTPS listener."
  type        = number
  default     = 443

  validation {
    condition     = var.https_listener_port >= 1 && var.https_listener_port <= 65535
    error_message = "https_listener_port must be a valid TCP port."
  }
}

variable "https_certificate_arn" {
  description = "ACM certificate ARN for the optional HTTPS listener. Keep null in committed examples; use only user-owned values outside this repo."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition = var.https_certificate_arn == null ? true : can(regex(
      "^arn:aws[a-zA-Z-]*:acm:[a-z0-9-]+:[0-9]{12}:certificate/.+",
      var.https_certificate_arn
    ))
    error_message = "https_certificate_arn must be an ACM certificate ARN when provided."
  }
}

variable "https_ssl_policy" {
  description = "SSL policy for the optional HTTPS listener. Review before real production use."
  type        = string
  default     = "ELBSecurityPolicy-2016-08"

  validation {
    condition     = length(trimspace(var.https_ssl_policy)) > 0
    error_message = "https_ssl_policy must not be empty."
  }
}

variable "default_response_status_code" {
  description = "Status code returned by the listener default fixed response for unmatched routes."
  type        = string
  default     = "404"

  validation {
    condition     = can(regex("^[245][0-9][0-9]$", var.default_response_status_code))
    error_message = "default_response_status_code must be a 2xx, 4xx, or 5xx status code string."
  }
}

variable "default_response_content_type" {
  description = "Content type returned by the listener default fixed response."
  type        = string
  default     = "text/plain"

  validation {
    condition = contains([
      "text/plain",
      "text/css",
      "text/html",
      "application/javascript",
      "application/json",
    ], var.default_response_content_type)
    error_message = "default_response_content_type must be one of the ALB fixed-response content types."
  }
}

variable "default_response_message_body" {
  description = "Message body returned by the listener default fixed response for unmatched routes."
  type        = string
  default     = "No matching platform route. Check the service path rules."

  validation {
    condition     = length(var.default_response_message_body) <= 1024
    error_message = "default_response_message_body must be 1024 characters or fewer."
  }
}

variable "access_logs_enabled" {
  description = "Whether ALB access logs are enabled. Defaults to false because no real log bucket is committed."
  type        = bool
  default     = false
}

variable "access_logs_bucket" {
  description = "Existing user-owned S3 bucket for ALB access logs when enabled. Keep null in committed examples."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition = var.access_logs_bucket == null ? true : can(regex(
      "^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$",
      var.access_logs_bucket
    ))
    error_message = "access_logs_bucket must look like an S3 bucket name when provided."
  }
}

variable "access_logs_prefix" {
  description = "Optional prefix for ALB access logs. Defaults to <name_prefix>/alb when access logs are enabled."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = var.access_logs_prefix == null ? true : !startswith(var.access_logs_prefix, "/")
    error_message = "access_logs_prefix must be relative and must not start with /."
  }
}

variable "common_tags" {
  description = "Common public-safe tags applied to taggable load balancer resources."
  type        = map(string)
  default     = {}
}
