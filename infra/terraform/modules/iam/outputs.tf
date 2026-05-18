output "ecs_task_execution_role_name" {
  description = "Name of the ECS task execution role used by ECS to pull images, write logs, and resolve approved secret references."
  value       = aws_iam_role.task_execution.name
}

output "ecs_task_execution_role_arn" {
  description = "ARN of the ECS task execution role for future task definitions."
  value       = aws_iam_role.task_execution.arn
}

output "ecs_task_role_name" {
  description = "Name of the application ECS task role."
  value       = aws_iam_role.task.name
}

output "ecs_task_role_arn" {
  description = "ARN of the application ECS task role for future task definitions."
  value       = aws_iam_role.task.arn
}

output "execution_secret_policy_name" {
  description = "Name of the inline execution-role secret-reference read policy, or null when no execution secret references are configured."
  value       = try(aws_iam_role_policy.execution_secret_references[0].name, null)
}

output "task_secret_policy_name" {
  description = "Name of the inline task-role secret-reference read policy, or null when no application secret references are configured."
  value       = try(aws_iam_role_policy.task_secret_references[0].name, null)
}

output "secret_reference_policy_summary" {
  description = "Review-friendly summary of IAM secret-reference read policies. These are references only; no secret values are output."
  value = {
    execution_role = {
      policy_created              = local.execution_secret_read_policy_enabled
      secrets_manager_references  = var.execution_secret_reference_arns
      ssm_parameter_references    = var.execution_ssm_parameter_arns
      customer_managed_kms_keys   = var.execution_kms_key_arns
      attached_aws_managed_policy = "AmazonECSTaskExecutionRolePolicy"
    }
    task_role = {
      policy_created             = local.task_secret_read_policy_enabled
      secrets_manager_references = var.task_secret_reference_arns
      ssm_parameter_references   = var.task_ssm_parameter_arns
      customer_managed_kms_keys  = var.task_kms_key_arns
      baseline_permissions       = "no application permissions unless explicit references are supplied"
    }
  }
}

output "iam_role_summary" {
  description = "Review-friendly summary of ECS IAM role separation."
  value = {
    task_execution_role = aws_iam_role.task_execution.name
    task_role           = aws_iam_role.task.name
    separation_intent   = "execution role is for ECS runtime integration; task role is for application AWS API access"
  }
}
