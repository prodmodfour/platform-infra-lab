output "load_balancer_security_group_id" {
  description = "Security group ID for the public Application Load Balancer edge."
  value       = aws_security_group.load_balancer.id
}

output "ecs_service_security_group_id" {
  description = "Security group ID for private ECS services."
  value       = aws_security_group.ecs_service.id
}

output "rds_postgres_security_group_id" {
  description = "Security group ID for private PostgreSQL/RDS resources."
  value       = aws_security_group.rds_postgres.id
}

output "redis_cache_security_group_id" {
  description = "Security group ID for private Redis/ElastiCache resources when enabled; null otherwise."
  value       = try(aws_security_group.redis_cache[0].id, null)
}

output "security_group_ids" {
  description = "Map of security group IDs created by this module. Redis is omitted when disabled."
  value = merge(
    {
      load_balancer = aws_security_group.load_balancer.id
      ecs_service   = aws_security_group.ecs_service.id
      rds_postgres  = aws_security_group.rds_postgres.id
    },
    var.enable_redis ? { redis_cache = aws_security_group.redis_cache[0].id } : {}
  )
}

output "rule_summary" {
  description = "Human-readable summary of the intended security group traffic boundaries."
  value = {
    alb_ingress_cidrs = var.alb_ingress_cidrs
    alb_ingress_ports = var.alb_ingress_ports
    alb_to_service    = "tcp/${var.service_port} from load_balancer security group to ecs_service security group"
    service_to_db     = "tcp/${var.database_port} from ecs_service security group to rds_postgres security group"
    service_to_redis  = var.enable_redis ? "tcp/${var.redis_port} from ecs_service security group to redis_cache security group" : "redis disabled; no cache security group or rules created"
    public_db_cache   = "no public ingress rules are created for database or cache security groups"
  }
}
