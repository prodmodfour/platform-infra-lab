output "dashboard_name" {
  description = "CloudWatch dashboard name for the environment."
  value       = aws_cloudwatch_dashboard.this.dashboard_name
}

output "dashboard_arn" {
  description = "CloudWatch dashboard ARN for the environment."
  value       = aws_cloudwatch_dashboard.this.dashboard_arn
}

output "log_group_naming_convention" {
  description = "Expected ECS service log group naming convention used by dashboard log widgets."
  value       = local.log_group_naming_convention
}

output "alarm_names" {
  description = "CloudWatch alarm names created by this module, grouped by platform area."
  value = {
    alb_5xx               = aws_cloudwatch_metric_alarm.alb_5xx.alarm_name
    alb_unhealthy_targets = { for service_name, alarm in aws_cloudwatch_metric_alarm.alb_unhealthy_targets : service_name => alarm.alarm_name }
    ecs_cpu               = { for service_name, alarm in aws_cloudwatch_metric_alarm.ecs_cpu : service_name => alarm.alarm_name }
    ecs_memory            = { for service_name, alarm in aws_cloudwatch_metric_alarm.ecs_memory : service_name => alarm.alarm_name }
    rds_cpu               = aws_cloudwatch_metric_alarm.rds_cpu.alarm_name
    rds_free_storage      = aws_cloudwatch_metric_alarm.rds_free_storage.alarm_name
  }
}

output "alarm_arns" {
  description = "CloudWatch alarm ARNs created by this module, grouped by platform area."
  value = {
    alb_5xx               = aws_cloudwatch_metric_alarm.alb_5xx.arn
    alb_unhealthy_targets = { for service_name, alarm in aws_cloudwatch_metric_alarm.alb_unhealthy_targets : service_name => alarm.arn }
    ecs_cpu               = { for service_name, alarm in aws_cloudwatch_metric_alarm.ecs_cpu : service_name => alarm.arn }
    ecs_memory            = { for service_name, alarm in aws_cloudwatch_metric_alarm.ecs_memory : service_name => alarm.arn }
    rds_cpu               = aws_cloudwatch_metric_alarm.rds_cpu.arn
    rds_free_storage      = aws_cloudwatch_metric_alarm.rds_free_storage.arn
  }
}

output "dashboard_summary" {
  description = "Review-friendly summary of dashboard coverage."
  value = {
    dashboard_name              = aws_cloudwatch_dashboard.this.dashboard_name
    aws_region                  = var.aws_region
    load_balancer_name          = var.load_balancer_name
    ecs_cluster_name            = var.ecs_cluster_name
    ecs_service_names           = local.sorted_service_keys
    rds_instance_identifier     = var.rds_instance_identifier
    log_group_naming_convention = local.log_group_naming_convention
    dashboard_period_seconds    = var.dashboard_period_seconds
  }
}

output "alarm_summary" {
  description = "Review-friendly summary of alarm thresholds and action wiring."
  value = {
    actions_enabled                         = var.actions_enabled
    alarm_actions_configured                = length(var.alarm_actions) > 0
    ok_actions_configured                   = length(var.ok_actions) > 0
    insufficient_data_actions_configured    = length(var.insufficient_data_actions) > 0
    alarm_period_seconds                    = var.alarm_period_seconds
    alb_5xx_alarm_threshold                 = var.alb_5xx_alarm_threshold
    alb_5xx_evaluation_periods              = var.alb_5xx_evaluation_periods
    alb_unhealthy_target_threshold          = var.alb_unhealthy_target_threshold
    alb_unhealthy_target_evaluation_periods = var.alb_unhealthy_target_evaluation_periods
    ecs_cpu_alarm_threshold_percent         = var.ecs_cpu_alarm_threshold_percent
    ecs_memory_alarm_threshold_percent      = var.ecs_memory_alarm_threshold_percent
    ecs_alarm_evaluation_periods            = var.ecs_alarm_evaluation_periods
    rds_cpu_alarm_threshold_percent         = var.rds_cpu_alarm_threshold_percent
    rds_free_storage_threshold_bytes        = var.rds_free_storage_space_threshold_bytes
    rds_alarm_evaluation_periods            = var.rds_alarm_evaluation_periods
  }
}
