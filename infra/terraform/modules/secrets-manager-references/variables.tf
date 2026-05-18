variable "name_prefix" {
  description = "Public-safe prefix used for tags and review summaries. Secret resource names use secret_path_prefix."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]+$", var.name_prefix)) && length(var.name_prefix) <= 40
    error_message = "name_prefix must be lowercase kebab-case and no more than 40 characters."
  }
}

variable "environment" {
  description = "Environment name used for tags and review context."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]+$", var.environment))
    error_message = "environment must be lowercase kebab-case."
  }
}

variable "secret_path_prefix" {
  description = "Public-safe Secrets Manager path prefix, such as platform-infra-lab/dev. Do not include a leading or trailing slash."
  type        = string

  validation {
    condition = can(regex(
      "^[a-z][a-z0-9-]+/[a-z][a-z0-9-]+$",
      var.secret_path_prefix
    ))
    error_message = "secret_path_prefix must look like project/environment in lowercase kebab-case without leading or trailing slashes."
  }
}

variable "ecs_execution_secret_definitions" {
  description = "Secrets Manager secret metadata to create for ECS task-definition secret injection. Keys are service names and container environment variable names; values are metadata only, never secret values."
  type = map(map(object({
    secret_name = string
    description = string
  })))
  default = {}

  validation {
    condition = alltrue([
      for service_name, secrets in var.ecs_execution_secret_definitions :
      can(regex("^[a-z][a-z0-9-]+$", service_name)) && length(secrets) > 0
    ])
    error_message = "ecs_execution_secret_definitions service keys must be lowercase kebab-case and each service must define at least one secret when present."
  }

  validation {
    condition = alltrue(flatten([
      for _, secrets in var.ecs_execution_secret_definitions : [
        for environment_variable_name, config in secrets :
        can(regex("^[A-Z_][A-Z0-9_]*$", environment_variable_name)) &&
        can(regex("^[a-z][a-z0-9-]+$", config.secret_name)) &&
        length(trimspace(config.description)) >= 20
      ]
    ]))
    error_message = "Secret environment variable names must be uppercase identifiers, secret_name must be lowercase kebab-case, and descriptions must explain the placeholder reference."
  }
}

variable "kms_key_id" {
  description = "Optional user-owned KMS key ID/ARN/alias for Secrets Manager encryption. Keep null in committed examples."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = var.kms_key_id == null ? true : length(trimspace(var.kms_key_id)) > 0
    error_message = "kms_key_id must be null or a non-empty KMS key identifier."
  }
}

variable "recovery_window_in_days" {
  description = "Secrets Manager deletion recovery window for metadata-only secret containers. Use 7-30 days; no immediate deletion in committed examples."
  type        = number
  default     = 7

  validation {
    condition     = var.recovery_window_in_days >= 7 && var.recovery_window_in_days <= 30
    error_message = "recovery_window_in_days must be between 7 and 30 days."
  }
}

variable "common_tags" {
  description = "Common public-safe tags applied to Secrets Manager secret metadata resources."
  type        = map(string)
  default     = {}
}
