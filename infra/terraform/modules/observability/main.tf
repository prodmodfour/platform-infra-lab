locals {
  component_name = "observability"
  dashboard_name = coalesce(var.dashboard_name, "${var.name_prefix}-observability")

  component_tags = merge(var.common_tags, {
    Environment = var.environment
    Component   = local.component_name
  })

  sorted_service_keys = sort(keys(var.ecs_services))

  log_group_naming_convention = "/aws/ecs/${var.name_prefix}/<service-name>"

  alb_metric_rows = [
    [
      "AWS/ApplicationELB",
      "HTTPCode_ELB_5XX_Count",
      "LoadBalancer",
      var.load_balancer_arn_suffix,
      {
        label = "ALB 5xx count"
        stat  = "Sum"
      },
    ],
    [
      "AWS/ApplicationELB",
      "TargetResponseTime",
      "LoadBalancer",
      var.load_balancer_arn_suffix,
      {
        label = "ALB target p95 latency"
        stat  = "p95"
      },
    ],
  ]

  alb_target_health_metric_rows = [
    for service_key in local.sorted_service_keys : [
      "AWS/ApplicationELB",
      "UnHealthyHostCount",
      "LoadBalancer",
      var.load_balancer_arn_suffix,
      "TargetGroup",
      var.ecs_services[service_key].target_group_arn_suffix,
      {
        label = "${service_key} unhealthy targets"
        stat  = "Maximum"
      },
    ]
  ]

  ecs_cpu_metric_rows = [
    for service_key in local.sorted_service_keys : [
      "AWS/ECS",
      "CPUUtilization",
      "ClusterName",
      var.ecs_cluster_name,
      "ServiceName",
      var.ecs_services[service_key].service_name,
      {
        label = "${service_key} CPU"
        stat  = "Average"
      },
    ]
  ]

  ecs_memory_metric_rows = [
    for service_key in local.sorted_service_keys : [
      "AWS/ECS",
      "MemoryUtilization",
      "ClusterName",
      var.ecs_cluster_name,
      "ServiceName",
      var.ecs_services[service_key].service_name,
      {
        label = "${service_key} memory"
        stat  = "Average"
      },
    ]
  ]

  ecs_metric_rows = concat(local.ecs_cpu_metric_rows, local.ecs_memory_metric_rows)

  rds_metric_rows = [
    [
      "AWS/RDS",
      "CPUUtilization",
      "DBInstanceIdentifier",
      var.rds_instance_identifier,
      {
        label = "RDS CPU"
        stat  = "Average"
      },
    ],
    [
      "AWS/RDS",
      "FreeStorageSpace",
      "DBInstanceIdentifier",
      var.rds_instance_identifier,
      {
        label = "RDS free storage"
        stat  = "Average"
      },
    ],
    [
      "AWS/RDS",
      "DatabaseConnections",
      "DBInstanceIdentifier",
      var.rds_instance_identifier,
      {
        label = "RDS connections"
        stat  = "Average"
      },
    ],
  ]

  service_log_widgets = [
    for index, service_key in local.sorted_service_keys : {
      type   = "log"
      x      = 0
      y      = 15 + (index * 6)
      width  = 24
      height = 6

      properties = {
        region = var.aws_region
        title  = "${service_key} recent container logs"
        view   = "table"
        query  = "SOURCE '${var.ecs_services[service_key].log_group_name}' | fields @timestamp, @message | sort @timestamp desc | limit 20"
      }
    }
  ]

  dashboard_widgets = concat(
    [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = local.alb_metric_rows
          period  = var.dashboard_period_seconds
          region  = var.aws_region
          title   = "ALB errors and latency"
          view    = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = local.alb_target_health_metric_rows
          period  = var.dashboard_period_seconds
          region  = var.aws_region
          title   = "Target health by ECS service"
          view    = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = local.ecs_metric_rows
          period  = var.dashboard_period_seconds
          region  = var.aws_region
          title   = "ECS service CPU and memory"
          view    = "timeSeries"
          yAxis = {
            left = {
              min = 0
              max = 100
            }
          }
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = local.rds_metric_rows
          period  = var.dashboard_period_seconds
          region  = var.aws_region
          title   = "RDS PostgreSQL health"
          view    = "timeSeries"
        }
      },
      {
        type   = "text"
        x      = 0
        y      = 12
        width  = 24
        height = 3

        properties = {
          markdown = "### ${var.environment} observability notes\n- ECS service log groups follow `${local.log_group_naming_convention}`.\n- Alarms are defined for ALB 5xx, unhealthy targets, ECS CPU/memory, and RDS CPU/free storage.\n- Alarm actions are empty unless user-owned SNS or incident-routing ARNs are supplied outside this repo."
        }
      },
    ],
    local.service_log_widgets
  )
}

resource "aws_cloudwatch_dashboard" "this" {
  dashboard_name = local.dashboard_name

  dashboard_body = jsonencode({
    widgets = local.dashboard_widgets
  })
}

resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "${var.name_prefix}-alb-5xx"
  alarm_description   = "Application Load Balancer 5xx responses exceeded the review threshold for ${var.environment}."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alb_5xx_evaluation_periods
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = var.alarm_period_seconds
  statistic           = "Sum"
  threshold           = var.alb_5xx_alarm_threshold
  treat_missing_data  = "notBreaching"
  unit                = "Count"

  dimensions = {
    LoadBalancer = var.load_balancer_arn_suffix
  }

  actions_enabled           = var.actions_enabled
  alarm_actions             = var.alarm_actions
  ok_actions                = var.ok_actions
  insufficient_data_actions = var.insufficient_data_actions

  tags = merge(local.component_tags, {
    Name = "${var.name_prefix}-alb-5xx"
    Tier = "alerting"
  })
}

resource "aws_cloudwatch_metric_alarm" "alb_unhealthy_targets" {
  for_each = var.ecs_services

  alarm_name          = "${var.name_prefix}-${each.key}-unhealthy-targets"
  alarm_description   = "ALB target group for ${each.key} has unhealthy targets in ${var.environment}."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alb_unhealthy_target_evaluation_periods
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = var.alarm_period_seconds
  statistic           = "Maximum"
  threshold           = var.alb_unhealthy_target_threshold
  treat_missing_data  = "notBreaching"
  unit                = "Count"

  dimensions = {
    LoadBalancer = var.load_balancer_arn_suffix
    TargetGroup  = each.value.target_group_arn_suffix
  }

  actions_enabled           = var.actions_enabled
  alarm_actions             = var.alarm_actions
  ok_actions                = var.ok_actions
  insufficient_data_actions = var.insufficient_data_actions

  tags = merge(local.component_tags, {
    Name    = "${var.name_prefix}-${each.key}-unhealthy-targets"
    Tier    = "alerting"
    Service = each.key
  })
}

resource "aws_cloudwatch_metric_alarm" "ecs_cpu" {
  for_each = var.ecs_services

  alarm_name          = "${var.name_prefix}-${each.key}-ecs-cpu-high"
  alarm_description   = "ECS service ${each.key} average CPU utilization is above the review threshold in ${var.environment}."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.ecs_alarm_evaluation_periods
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = var.alarm_period_seconds
  statistic           = "Average"
  threshold           = var.ecs_cpu_alarm_threshold_percent
  treat_missing_data  = "notBreaching"
  unit                = "Percent"

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = each.value.service_name
  }

  actions_enabled           = var.actions_enabled
  alarm_actions             = var.alarm_actions
  ok_actions                = var.ok_actions
  insufficient_data_actions = var.insufficient_data_actions

  tags = merge(local.component_tags, {
    Name    = "${var.name_prefix}-${each.key}-ecs-cpu-high"
    Tier    = "alerting"
    Service = each.key
  })
}

resource "aws_cloudwatch_metric_alarm" "ecs_memory" {
  for_each = var.ecs_services

  alarm_name          = "${var.name_prefix}-${each.key}-ecs-memory-high"
  alarm_description   = "ECS service ${each.key} average memory utilization is above the review threshold in ${var.environment}."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.ecs_alarm_evaluation_periods
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = var.alarm_period_seconds
  statistic           = "Average"
  threshold           = var.ecs_memory_alarm_threshold_percent
  treat_missing_data  = "notBreaching"
  unit                = "Percent"

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = each.value.service_name
  }

  actions_enabled           = var.actions_enabled
  alarm_actions             = var.alarm_actions
  ok_actions                = var.ok_actions
  insufficient_data_actions = var.insufficient_data_actions

  tags = merge(local.component_tags, {
    Name    = "${var.name_prefix}-${each.key}-ecs-memory-high"
    Tier    = "alerting"
    Service = each.key
  })
}

resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name          = "${var.name_prefix}-rds-cpu-high"
  alarm_description   = "RDS PostgreSQL CPU utilization is above the review threshold in ${var.environment}."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.rds_alarm_evaluation_periods
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = var.alarm_period_seconds
  statistic           = "Average"
  threshold           = var.rds_cpu_alarm_threshold_percent
  treat_missing_data  = "notBreaching"
  unit                = "Percent"

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_identifier
  }

  actions_enabled           = var.actions_enabled
  alarm_actions             = var.alarm_actions
  ok_actions                = var.ok_actions
  insufficient_data_actions = var.insufficient_data_actions

  tags = merge(local.component_tags, {
    Name = "${var.name_prefix}-rds-cpu-high"
    Tier = "alerting"
  })
}

resource "aws_cloudwatch_metric_alarm" "rds_free_storage" {
  alarm_name          = "${var.name_prefix}-rds-free-storage-low"
  alarm_description   = "RDS PostgreSQL free storage is below the review threshold in ${var.environment}."
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = var.rds_alarm_evaluation_periods
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = var.alarm_period_seconds
  statistic           = "Average"
  threshold           = var.rds_free_storage_space_threshold_bytes
  treat_missing_data  = "notBreaching"
  unit                = "Bytes"

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_identifier
  }

  actions_enabled           = var.actions_enabled
  alarm_actions             = var.alarm_actions
  ok_actions                = var.ok_actions
  insufficient_data_actions = var.insufficient_data_actions

  tags = merge(local.component_tags, {
    Name = "${var.name_prefix}-rds-free-storage-low"
    Tier = "alerting"
  })
}
