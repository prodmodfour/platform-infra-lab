output "load_balancer_name" {
  description = "Name of the Application Load Balancer."
  value       = aws_lb.this.name
}

output "load_balancer_arn" {
  description = "ARN of the Application Load Balancer."
  value       = aws_lb.this.arn
}

output "load_balancer_arn_suffix" {
  description = "ARN suffix of the Application Load Balancer used by CloudWatch ApplicationELB metric dimensions."
  value       = aws_lb.this.arn_suffix
}

output "load_balancer_dns_name" {
  description = "DNS name assigned to the Application Load Balancer."
  value       = aws_lb.this.dns_name
}

output "load_balancer_zone_id" {
  description = "Canonical hosted zone ID for ALB DNS alias records."
  value       = aws_lb.this.zone_id
}

output "http_listener_arn" {
  description = "ARN of the HTTP listener used by ECS service listener rules."
  value       = aws_lb_listener.http.arn
}

output "http_listener_port" {
  description = "Port used by the HTTP listener."
  value       = aws_lb_listener.http.port
}

output "https_listener_arn" {
  description = "ARN of the optional HTTPS listener when enabled, otherwise null."
  value       = try(aws_lb_listener.https[0].arn, null)
}

output "https_listener_port" {
  description = "Port used by the optional HTTPS listener when enabled, otherwise null."
  value       = try(aws_lb_listener.https[0].port, null)
}

output "security_group_ids" {
  description = "Security group IDs attached to the ALB."
  value       = aws_lb.this.security_groups
}

output "public_subnet_ids" {
  description = "Public subnet IDs used by the ALB."
  value       = aws_lb.this.subnets
}

output "access_logs" {
  description = "Review-friendly ALB access log configuration. Bucket is a reference only, not a secret."
  value = {
    enabled = var.access_logs_enabled
    bucket  = var.access_logs_enabled ? var.access_logs_bucket : null
    prefix  = var.access_logs_enabled ? local.access_logs_prefix : null
  }
}

output "target_group_wiring_pattern" {
  description = "Review-friendly summary of how service target groups are connected to this ALB."
  value = {
    default_listener_action = "fixed-response"
    ecs_service_module      = "creates target groups and listener rules"
    http_listener_output    = "http_listener_arn"
    https_listener_output   = var.enable_https_listener ? "https_listener_arn" : null
  }
}

output "listener_summary" {
  description = "Review-friendly summary of listeners created by this module."
  value = {
    http = {
      enabled      = true
      port         = aws_lb_listener.http.port
      protocol     = aws_lb_listener.http.protocol
      listener_arn = aws_lb_listener.http.arn
    }
    https = {
      enabled      = var.enable_https_listener
      port         = try(aws_lb_listener.https[0].port, null)
      protocol     = var.enable_https_listener ? "HTTPS" : null
      listener_arn = try(aws_lb_listener.https[0].arn, null)
    }
  }
}
