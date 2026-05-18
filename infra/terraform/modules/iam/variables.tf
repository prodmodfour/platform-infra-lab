variable "name_prefix" {
  description = "Public-safe prefix used for IAM role and policy names. Keep this short enough for IAM name limits."
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
    condition     = length(trimspace(var.environment)) > 0
    error_message = "environment must not be empty."
  }
}

variable "execution_secret_reference_arns" {
  description = "Secrets Manager secret ARNs that the ECS task execution role may read for ECS-managed container secret injection. Use references only, never secret values."
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for arn in var.execution_secret_reference_arns :
      trimspace(arn) != "*" && can(regex("^arn:aws[a-zA-Z-]*:secretsmanager:[a-z0-9-]+:[0-9]{12}:secret:.+", arn))
    ])
    error_message = "execution_secret_reference_arns must contain Secrets Manager secret ARNs, not wildcard resources or secret values."
  }
}

variable "execution_ssm_parameter_arns" {
  description = "SSM Parameter Store parameter ARNs that the ECS task execution role may read for ECS-managed container secret injection. Use references only, never parameter values."
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for arn in var.execution_ssm_parameter_arns :
      trimspace(arn) != "*" && can(regex("^arn:aws[a-zA-Z-]*:ssm:[a-z0-9-]+:[0-9]{12}:parameter/.+", arn))
    ])
    error_message = "execution_ssm_parameter_arns must contain SSM parameter ARNs, not wildcard resources or parameter values."
  }
}

variable "execution_kms_key_arns" {
  description = "Optional KMS key ARNs the ECS task execution role may decrypt when approved secret references use customer-managed keys."
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for arn in var.execution_kms_key_arns :
      trimspace(arn) != "*" && can(regex("^arn:aws[a-zA-Z-]*:kms:[a-z0-9-]+:[0-9]{12}:key/.+", arn))
    ])
    error_message = "execution_kms_key_arns must contain KMS key ARNs, not wildcard resources."
  }
}

variable "task_secret_reference_arns" {
  description = "Secrets Manager secret ARNs that application code may read through the ECS task role. Use references only, never secret values."
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for arn in var.task_secret_reference_arns :
      trimspace(arn) != "*" && can(regex("^arn:aws[a-zA-Z-]*:secretsmanager:[a-z0-9-]+:[0-9]{12}:secret:.+", arn))
    ])
    error_message = "task_secret_reference_arns must contain Secrets Manager secret ARNs, not wildcard resources or secret values."
  }
}

variable "task_ssm_parameter_arns" {
  description = "SSM Parameter Store parameter ARNs that application code may read through the ECS task role. Use references only, never parameter values."
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for arn in var.task_ssm_parameter_arns :
      trimspace(arn) != "*" && can(regex("^arn:aws[a-zA-Z-]*:ssm:[a-z0-9-]+:[0-9]{12}:parameter/.+", arn))
    ])
    error_message = "task_ssm_parameter_arns must contain SSM parameter ARNs, not wildcard resources or parameter values."
  }
}

variable "task_kms_key_arns" {
  description = "Optional KMS key ARNs the application task role may decrypt when approved secret references use customer-managed keys."
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for arn in var.task_kms_key_arns :
      trimspace(arn) != "*" && can(regex("^arn:aws[a-zA-Z-]*:kms:[a-z0-9-]+:[0-9]{12}:key/.+", arn))
    ])
    error_message = "task_kms_key_arns must contain KMS key ARNs, not wildcard resources."
  }
}

variable "common_tags" {
  description = "Common public-safe tags applied to taggable IAM resources."
  type        = map(string)
  default     = {}
}
