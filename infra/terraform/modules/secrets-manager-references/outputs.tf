output "ecs_secret_references_by_service" {
  description = "ECS task-definition secret references as service => environment variable => Secrets Manager ARN. These are references only, not secret values."
  value = {
    for service_name, secrets in var.ecs_execution_secret_definitions : service_name => {
      for environment_variable_name, _ in secrets :
      environment_variable_name => aws_secretsmanager_secret.ecs_execution["${service_name}:${environment_variable_name}"].arn
    }
  }
}

output "ecs_execution_secret_arns" {
  description = "Secrets Manager ARNs that the ECS task execution role needs to resolve container secret references."
  value = [
    for key in sort(keys(aws_secretsmanager_secret.ecs_execution)) :
    aws_secretsmanager_secret.ecs_execution[key].arn
  ]
}

output "ecs_secret_names_by_service" {
  description = "Secrets Manager names by service and environment variable. Names are not values or credentials."
  value = {
    for service_name, secrets in var.ecs_execution_secret_definitions : service_name => {
      for environment_variable_name, _ in secrets :
      environment_variable_name => aws_secretsmanager_secret.ecs_execution["${service_name}:${environment_variable_name}"].name
    }
  }
}

output "secret_metadata_summary" {
  description = "Review-friendly summary of metadata-only Secrets Manager resources. No secret values are exposed."
  value = {
    secret_manager                     = "aws-secrets-manager"
    name_prefix                        = var.name_prefix
    secret_path_prefix                 = var.secret_path_prefix
    service_count                      = length(var.ecs_execution_secret_definitions)
    secret_count                       = length(local.ecs_execution_secret_map)
    services_with_secret_references    = sort(keys(var.ecs_execution_secret_definitions))
    recovery_window_in_days            = var.recovery_window_in_days
    kms_key_supplied                   = var.kms_key_id != null
    secret_version_resources_created   = false
    secret_values_created_by_terraform = false
  }
}

output "value_management_summary" {
  description = "How secret values are intentionally kept out of this public repository."
  value = {
    secret_values_in_repo             = false
    secret_values_in_terraform_state  = false
    terraform_manages_secret_versions = false
    value_owner                       = "created outside this repository or by a secure user-owned pipeline"
    ecs_consumes                      = "Secrets Manager ARNs passed to ECS task-definition secret references"
    rotation_owner                    = "user-owned secret lifecycle outside this module"
  }
}
