locals {
  component_tags = merge(var.common_tags, {
    Environment = var.environment
    Component   = "ecs-service"
    Service     = var.service_name
  })

  service_full_name      = "${var.name_prefix}-${var.service_name}"
  target_group_name      = "${var.environment}-${var.service_name}-tg"
  log_group_name         = "/aws/ecs/${var.name_prefix}/${var.service_name}"
  listener_path_patterns = length(var.listener_rule_path_patterns) > 0 ? var.listener_rule_path_patterns : ["/${var.service_name}*"]

  container_environment = [
    for name in sort(keys(var.environment_variables)) : {
      name  = name
      value = var.environment_variables[name]
    }
  ]

  container_secrets = [
    for name in sort(keys(var.secret_references)) : {
      name      = name
      valueFrom = var.secret_references[name]
    }
  ]

  container_health_check_command = length(var.container_health_check_command) > 0 ? var.container_health_check_command : [
    "CMD-SHELL",
    "curl -fsS http://127.0.0.1:${var.container_port}${var.health_check_path} || exit 1",
  ]

  container_definition = {
    name                   = var.service_name
    image                  = var.container_image
    essential              = true
    cpu                    = var.cpu
    memory                 = var.memory
    readonlyRootFilesystem = var.readonly_root_filesystem

    portMappings = [
      {
        containerPort = var.container_port
        hostPort      = var.container_port
        protocol      = "tcp"
      }
    ]

    environment = local.container_environment
    secrets     = local.container_secrets

    healthCheck = {
      command     = local.container_health_check_command
      interval    = var.container_health_check_interval
      timeout     = var.container_health_check_timeout
      retries     = var.container_health_check_retries
      startPeriod = var.container_health_check_start_period
    }

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.this.name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = var.service_name
      }
    }
  }
}

resource "aws_cloudwatch_log_group" "this" {
  name              = local.log_group_name
  retention_in_days = var.log_retention_days

  tags = merge(local.component_tags, {
    Name = local.log_group_name
    Tier = "service-logs"
  })
}

resource "aws_lb_target_group" "this" {
  name                 = local.target_group_name
  port                 = var.container_port
  protocol             = var.target_group_protocol
  target_type          = "ip"
  vpc_id               = var.vpc_id
  deregistration_delay = var.deregistration_delay_seconds

  health_check {
    enabled             = true
    path                = var.health_check_path
    protocol            = var.health_check_protocol
    matcher             = var.health_check_matcher
    port                = "traffic-port"
    interval            = var.health_check_interval
    timeout             = var.health_check_timeout
    healthy_threshold   = var.healthy_threshold
    unhealthy_threshold = var.unhealthy_threshold
  }

  tags = merge(local.component_tags, {
    Name = local.target_group_name
    Tier = "service-routing"
  })

  lifecycle {
    precondition {
      condition     = length(local.target_group_name) <= 32
      error_message = "Target group names must be 32 characters or fewer; shorten environment or service_name."
    }
  }
}

resource "aws_lb_listener_rule" "this" {
  count = var.create_listener_rule ? 1 : 0

  listener_arn = var.listener_arn
  priority     = var.listener_rule_priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }

  condition {
    path_pattern {
      values = local.listener_path_patterns
    }
  }

  tags = merge(local.component_tags, {
    Name = "${local.service_full_name}-listener-rule"
    Tier = "service-routing"
  })

  lifecycle {
    precondition {
      condition     = var.listener_arn != null && var.listener_rule_priority != null
      error_message = "listener_arn and listener_rule_priority are required when create_listener_rule is true."
    }
  }
}

resource "aws_ecs_task_definition" "this" {
  family                   = local.service_full_name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = tostring(var.cpu)
  memory                   = tostring(var.memory)
  execution_role_arn       = var.task_execution_role_arn
  task_role_arn            = var.task_role_arn
  container_definitions    = jsonencode([local.container_definition])

  runtime_platform {
    operating_system_family = var.operating_system_family
    cpu_architecture        = var.cpu_architecture
  }

  tags = merge(local.component_tags, {
    Name = local.service_full_name
    Tier = "service-runtime"
  })
}

resource "aws_ecs_service" "this" {
  name             = local.service_full_name
  cluster          = var.cluster_arn
  task_definition  = aws_ecs_task_definition.this.arn
  desired_count    = var.desired_count
  launch_type      = "FARGATE"
  platform_version = var.platform_version

  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
  deployment_maximum_percent         = var.deployment_maximum_percent
  health_check_grace_period_seconds  = var.health_check_grace_period_seconds
  enable_execute_command             = var.enable_execute_command
  propagate_tags                     = "SERVICE"

  deployment_circuit_breaker {
    enable   = var.deployment_circuit_breaker_enabled
    rollback = var.deployment_circuit_breaker_rollback
  }

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = var.security_group_ids
    assign_public_ip = var.assign_public_ip
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.this.arn
    container_name   = var.service_name
    container_port   = var.container_port
  }

  tags = merge(local.component_tags, {
    Name = local.service_full_name
    Tier = "private-service"
  })
}

resource "aws_appautoscaling_target" "desired_count" {
  count = var.enable_autoscaling ? 1 : 0

  max_capacity       = var.autoscaling_max_capacity
  min_capacity       = var.autoscaling_min_capacity
  resource_id        = "service/${var.cluster_name}/${aws_ecs_service.this.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  lifecycle {
    precondition {
      condition     = var.autoscaling_min_capacity <= var.autoscaling_max_capacity
      error_message = "autoscaling_min_capacity must be less than or equal to autoscaling_max_capacity."
    }
  }
}

resource "aws_appautoscaling_policy" "cpu" {
  count = var.enable_autoscaling ? 1 : 0

  name               = "${local.service_full_name}-cpu-target"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.desired_count[0].resource_id
  scalable_dimension = aws_appautoscaling_target.desired_count[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.desired_count[0].service_namespace

  target_tracking_scaling_policy_configuration {
    target_value       = var.autoscaling_cpu_target_value
    scale_in_cooldown  = var.autoscaling_scale_in_cooldown
    scale_out_cooldown = var.autoscaling_scale_out_cooldown

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
  }
}

resource "aws_appautoscaling_policy" "memory" {
  count = var.enable_autoscaling ? 1 : 0

  name               = "${local.service_full_name}-memory-target"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.desired_count[0].resource_id
  scalable_dimension = aws_appautoscaling_target.desired_count[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.desired_count[0].service_namespace

  target_tracking_scaling_policy_configuration {
    target_value       = var.autoscaling_memory_target_value
    scale_in_cooldown  = var.autoscaling_scale_in_cooldown
    scale_out_cooldown = var.autoscaling_scale_out_cooldown

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
  }
}
