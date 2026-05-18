output "service_name" {
  description = "Name of the ECS service."
  value       = aws_ecs_service.this.name
}

output "service_arn" {
  description = "ARN of the ECS service."
  value       = aws_ecs_service.this.id
}

output "task_definition_arn" {
  description = "ARN of the ECS task definition revision."
  value       = aws_ecs_task_definition.this.arn
}

output "task_definition_family" {
  description = "Task definition family name."
  value       = aws_ecs_task_definition.this.family
}

output "log_group_name" {
  description = "CloudWatch log group name for the service container."
  value       = aws_cloudwatch_log_group.this.name
}

output "log_group_arn" {
  description = "CloudWatch log group ARN for the service container."
  value       = aws_cloudwatch_log_group.this.arn
}

output "target_group_name" {
  description = "ALB target group name for the service."
  value       = aws_lb_target_group.this.name
}

output "target_group_arn" {
  description = "ALB target group ARN for the service."
  value       = aws_lb_target_group.this.arn
}

output "listener_rule_arn" {
  description = "ALB listener rule ARN when created, otherwise null."
  value       = try(aws_lb_listener_rule.this[0].arn, null)
}

output "autoscaling_resource_id" {
  description = "Application Auto Scaling resource ID for desired count when autoscaling is enabled, otherwise null."
  value       = try(aws_appautoscaling_target.desired_count[0].resource_id, null)
}

output "service_summary" {
  description = "Review-friendly summary of the ECS/Fargate service pattern. Secret references are ARNs only, not values."
  value = {
    service_name              = aws_ecs_service.this.name
    container_image           = var.container_image
    container_port            = var.container_port
    desired_count             = var.desired_count
    private_subnet_count      = length(var.private_subnet_ids)
    assign_public_ip          = var.assign_public_ip
    target_group_name         = aws_lb_target_group.this.name
    target_group_arn          = aws_lb_target_group.this.arn
    health_check_path         = var.health_check_path
    log_group_name            = aws_cloudwatch_log_group.this.name
    listener_rule_created     = var.create_listener_rule
    listener_path_patterns    = local.listener_path_patterns
    autoscaling_enabled       = var.enable_autoscaling
    autoscaling_min_capacity  = var.enable_autoscaling ? var.autoscaling_min_capacity : null
    autoscaling_max_capacity  = var.enable_autoscaling ? var.autoscaling_max_capacity : null
    environment_variable_keys = sort(keys(var.environment_variables))
    secret_reference_names    = sort(keys(var.secret_references))
  }
}
