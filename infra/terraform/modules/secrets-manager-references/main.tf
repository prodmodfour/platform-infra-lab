locals {
  component_tags = merge(var.common_tags, {
    Environment = var.environment
    Component   = "secrets-manager-references"
    NamePrefix  = var.name_prefix
  })

  ecs_execution_secret_items = flatten([
    for service_name, secrets in var.ecs_execution_secret_definitions : [
      for environment_variable_name, config in secrets : {
        key                       = "${service_name}:${environment_variable_name}"
        service_name              = service_name
        environment_variable_name = environment_variable_name
        secret_name               = config.secret_name
        description               = config.description
        full_secret_name          = "${var.secret_path_prefix}/ecs-execution/${service_name}/${config.secret_name}"
      }
    ]
  ])

  ecs_execution_secret_map = {
    for item in local.ecs_execution_secret_items : item.key => item
  }
}

resource "aws_secretsmanager_secret" "ecs_execution" {
  for_each = local.ecs_execution_secret_map

  name                    = each.value.full_secret_name
  description             = each.value.description
  kms_key_id              = var.kms_key_id
  recovery_window_in_days = var.recovery_window_in_days

  tags = merge(local.component_tags, {
    Name                 = each.value.full_secret_name
    SecretScope          = "ecs-execution"
    SecretValueManagedBy = "outside-this-repo"
    Service              = each.value.service_name
    EnvironmentVariable  = each.value.environment_variable_name
  })
}
