variable "name_prefix" {
  description = "Public-safe prefix used for named observability resources."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]+$", var.name_prefix))
    error_message = "name_prefix must be lowercase kebab-case."
  }
}

variable "environment" {
  description = "Environment name such as dev or prod."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]+$", var.environment))
    error_message = "environment must be lowercase kebab-case."
  }
}

variable "aws_region" {
  description = "AWS region displayed in dashboard widgets."
  type        = string

  validation {
    condition     = length(trimspace(var.aws_region)) > 0
    error_message = "aws_region must not be empty."
  }
}

variable "dashboard_name" {
  description = "Optional CloudWatch dashboard name. Defaults to <name_prefix>-observability."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = var.dashboard_name == null ? true : can(regex("^[A-Za-z0-9_-]{1,255}$", var.dashboard_name))
    error_message = "dashboard_name must use 1-255 alphanumeric, underscore, or hyphen characters when provided."
  }
}

variable "dashboard_period_seconds" {
  description = "Default CloudWatch dashboard widget period in seconds."
  type        = number
  default     = 300

  validation {
    condition     = var.dashboard_period_seconds >= 60 && var.dashboard_period_seconds % 60 == 0
    error_message = "dashboard_period_seconds must be at least 60 and divisible by 60."
  }
}

variable "alarm_period_seconds" {
  description = "CloudWatch alarm metric period in seconds."
  type        = number
  default     = 300

  validation {
    condition     = var.alarm_period_seconds >= 60 && var.alarm_period_seconds % 60 == 0
    error_message = "alarm_period_seconds must be at least 60 and divisible by 60."
  }
}

variable "load_balancer_name" {
  description = "Application Load Balancer name for dashboard summaries."
  type        = string
}

variable "load_balancer_arn_suffix" {
  description = "Application Load Balancer ARN suffix, for example app/name/id, used by CloudWatch ApplicationELB metric dimensions."
  type        = string
}

variable "ecs_cluster_name" {
  description = "ECS cluster name used by CloudWatch ECS service metric dimensions."
  type        = string
}

variable "ecs_services" {
  description = "ECS services to include in dashboards and alarms, keyed by public-safe service name."
  type = map(object({
    service_name            = string
    target_group_arn_suffix = string
    log_group_name          = string
  }))
  default = {}
}

variable "rds_instance_identifier" {
  description = "RDS PostgreSQL instance identifier used by CloudWatch RDS metric dimensions."
  type        = string
}

variable "actions_enabled" {
  description = "Whether CloudWatch alarm actions are enabled. Action lists default to empty in this public-safe repo."
  type        = bool
  default     = true
}

variable "alarm_actions" {
  description = "Optional user-owned alarm action ARNs, such as SNS topics. Keep empty in committed examples."
  type        = list(string)
  default     = []
}

variable "ok_actions" {
  description = "Optional user-owned OK action ARNs, such as SNS topics. Keep empty in committed examples."
  type        = list(string)
  default     = []
}

variable "insufficient_data_actions" {
  description = "Optional user-owned insufficient-data action ARNs. Keep empty in committed examples."
  type        = list(string)
  default     = []
}

variable "alb_5xx_alarm_threshold" {
  description = "Sum of ALB-generated 5xx responses during the evaluation window that should alarm."
  type        = number
  default     = 5

  validation {
    condition     = var.alb_5xx_alarm_threshold >= 0
    error_message = "alb_5xx_alarm_threshold must be zero or greater."
  }
}

variable "alb_5xx_evaluation_periods" {
  description = "Number of periods used by the ALB 5xx alarm."
  type        = number
  default     = 2

  validation {
    condition     = var.alb_5xx_evaluation_periods >= 1
    error_message = "alb_5xx_evaluation_periods must be at least 1."
  }
}

variable "alb_unhealthy_target_threshold" {
  description = "Maximum unhealthy targets in a service target group that should alarm."
  type        = number
  default     = 1

  validation {
    condition     = var.alb_unhealthy_target_threshold >= 0
    error_message = "alb_unhealthy_target_threshold must be zero or greater."
  }
}

variable "alb_unhealthy_target_evaluation_periods" {
  description = "Number of periods used by unhealthy-target alarms."
  type        = number
  default     = 2

  validation {
    condition     = var.alb_unhealthy_target_evaluation_periods >= 1
    error_message = "alb_unhealthy_target_evaluation_periods must be at least 1."
  }
}

variable "ecs_cpu_alarm_threshold_percent" {
  description = "Average ECS service CPU utilization percentage that should alarm."
  type        = number
  default     = 80

  validation {
    condition     = var.ecs_cpu_alarm_threshold_percent > 0 && var.ecs_cpu_alarm_threshold_percent <= 100
    error_message = "ecs_cpu_alarm_threshold_percent must be greater than 0 and less than or equal to 100."
  }
}

variable "ecs_memory_alarm_threshold_percent" {
  description = "Average ECS service memory utilization percentage that should alarm."
  type        = number
  default     = 85

  validation {
    condition     = var.ecs_memory_alarm_threshold_percent > 0 && var.ecs_memory_alarm_threshold_percent <= 100
    error_message = "ecs_memory_alarm_threshold_percent must be greater than 0 and less than or equal to 100."
  }
}

variable "ecs_alarm_evaluation_periods" {
  description = "Number of periods used by ECS CPU and memory alarms."
  type        = number
  default     = 3

  validation {
    condition     = var.ecs_alarm_evaluation_periods >= 1
    error_message = "ecs_alarm_evaluation_periods must be at least 1."
  }
}

variable "rds_cpu_alarm_threshold_percent" {
  description = "Average RDS PostgreSQL CPU utilization percentage that should alarm."
  type        = number
  default     = 80

  validation {
    condition     = var.rds_cpu_alarm_threshold_percent > 0 && var.rds_cpu_alarm_threshold_percent <= 100
    error_message = "rds_cpu_alarm_threshold_percent must be greater than 0 and less than or equal to 100."
  }
}

variable "rds_free_storage_space_threshold_bytes" {
  description = "Average RDS free storage threshold in bytes below which the storage alarm fires."
  type        = number
  default     = 2147483648

  validation {
    condition     = var.rds_free_storage_space_threshold_bytes > 0
    error_message = "rds_free_storage_space_threshold_bytes must be greater than zero."
  }
}

variable "rds_alarm_evaluation_periods" {
  description = "Number of periods used by RDS alarms."
  type        = number
  default     = 3

  validation {
    condition     = var.rds_alarm_evaluation_periods >= 1
    error_message = "rds_alarm_evaluation_periods must be at least 1."
  }
}

variable "common_tags" {
  description = "Common public-safe tags applied to taggable alarm resources."
  type        = map(string)
  default     = {}
}
