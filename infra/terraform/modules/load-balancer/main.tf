locals {
  component_tags = merge(var.common_tags, {
    Environment = var.environment
    Component   = "load-balancer"
  })

  load_balancer_name = "${var.name_prefix}-alb"
  access_logs_prefix = var.access_logs_prefix == null ? "${var.name_prefix}/alb" : var.access_logs_prefix
}

resource "aws_lb" "this" {
  name               = local.load_balancer_name
  internal           = var.internal
  load_balancer_type = "application"
  security_groups    = var.security_group_ids
  subnets            = var.public_subnet_ids

  drop_invalid_header_fields = var.drop_invalid_header_fields
  enable_deletion_protection = var.enable_deletion_protection
  enable_http2               = var.enable_http2
  idle_timeout               = var.idle_timeout_seconds

  dynamic "access_logs" {
    for_each = var.access_logs_enabled ? [1] : []

    content {
      bucket  = var.access_logs_bucket
      enabled = true
      prefix  = local.access_logs_prefix
    }
  }

  tags = merge(local.component_tags, {
    Name = local.load_balancer_name
    Tier = var.internal ? "private-edge" : "public-edge"
  })

  lifecycle {
    precondition {
      condition     = length(local.load_balancer_name) <= 32
      error_message = "Application Load Balancer names must be 32 characters or fewer; shorten name_prefix."
    }

    precondition {
      condition     = var.access_logs_enabled ? (var.access_logs_bucket != null ? length(trimspace(var.access_logs_bucket)) > 0 : false) : true
      error_message = "access_logs_bucket is required when access_logs_enabled is true."
    }
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = var.http_listener_port
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = var.default_response_content_type
      message_body = var.default_response_message_body
      status_code  = var.default_response_status_code
    }
  }

  tags = merge(local.component_tags, {
    Name = "${local.load_balancer_name}-http"
    Tier = "public-edge"
  })
}

resource "aws_lb_listener" "https" {
  count = var.enable_https_listener ? 1 : 0

  load_balancer_arn = aws_lb.this.arn
  port              = var.https_listener_port
  protocol          = "HTTPS"
  certificate_arn   = var.https_certificate_arn
  ssl_policy        = var.https_ssl_policy

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = var.default_response_content_type
      message_body = var.default_response_message_body
      status_code  = var.default_response_status_code
    }
  }

  tags = merge(local.component_tags, {
    Name = "${local.load_balancer_name}-https"
    Tier = "public-edge"
  })

  lifecycle {
    precondition {
      condition     = var.https_certificate_arn != null ? length(trimspace(var.https_certificate_arn)) > 0 : false
      error_message = "https_certificate_arn is required when enable_https_listener is true."
    }
  }
}
