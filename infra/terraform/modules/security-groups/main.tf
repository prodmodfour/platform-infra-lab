locals {
  component_tags = merge(var.common_tags, {
    Environment = var.environment
    Component   = "security-groups"
  })

  alb_ingress_rules = {
    for pair in setproduct(var.alb_ingress_cidrs, var.alb_ingress_ports) :
    format("%s-%s", replace(pair[0], "/", "_"), tostring(pair[1])) => {
      cidr = pair[0]
      port = pair[1]
    }
  }
}

resource "aws_security_group" "load_balancer" {
  name        = "${var.name_prefix}-alb-sg"
  description = "Public edge security group for the Application Load Balancer"
  vpc_id      = var.vpc_id

  revoke_rules_on_delete = true

  tags = merge(local.component_tags, {
    Name = "${var.name_prefix}-alb-sg"
    Tier = "public-edge"
  })
}

resource "aws_security_group" "ecs_service" {
  name        = "${var.name_prefix}-ecs-service-sg"
  description = "Private ECS service security group that only accepts ALB traffic"
  vpc_id      = var.vpc_id

  revoke_rules_on_delete = true

  tags = merge(local.component_tags, {
    Name = "${var.name_prefix}-ecs-service-sg"
    Tier = "private-service"
  })
}

resource "aws_security_group" "rds_postgres" {
  name        = "${var.name_prefix}-rds-postgres-sg"
  description = "Private PostgreSQL security group that only accepts ECS service traffic"
  vpc_id      = var.vpc_id

  revoke_rules_on_delete = true

  tags = merge(local.component_tags, {
    Name = "${var.name_prefix}-rds-postgres-sg"
    Tier = "private-data"
  })
}

resource "aws_security_group" "redis_cache" {
  count = var.enable_redis ? 1 : 0

  name        = "${var.name_prefix}-redis-cache-sg"
  description = "Private Redis cache security group that only accepts ECS service traffic"
  vpc_id      = var.vpc_id

  revoke_rules_on_delete = true

  tags = merge(local.component_tags, {
    Name = "${var.name_prefix}-redis-cache-sg"
    Tier = "private-cache"
  })
}

resource "aws_vpc_security_group_ingress_rule" "alb_public" {
  for_each = local.alb_ingress_rules

  security_group_id = aws_security_group.load_balancer.id
  cidr_ipv4         = each.value.cidr
  from_port         = each.value.port
  ip_protocol       = "tcp"
  to_port           = each.value.port
  description       = "Allow public HTTP/HTTPS edge traffic to the ALB only"
}

resource "aws_vpc_security_group_egress_rule" "alb_to_ecs" {
  security_group_id            = aws_security_group.load_balancer.id
  referenced_security_group_id = aws_security_group.ecs_service.id
  from_port                    = var.service_port
  ip_protocol                  = "tcp"
  to_port                      = var.service_port
  description                  = "Allow ALB to reach ECS service tasks on the application port"
}

resource "aws_vpc_security_group_ingress_rule" "ecs_from_alb" {
  security_group_id            = aws_security_group.ecs_service.id
  referenced_security_group_id = aws_security_group.load_balancer.id
  from_port                    = var.service_port
  ip_protocol                  = "tcp"
  to_port                      = var.service_port
  description                  = "Allow ECS service traffic only from the ALB security group"
}

resource "aws_vpc_security_group_egress_rule" "ecs_to_rds" {
  security_group_id            = aws_security_group.ecs_service.id
  referenced_security_group_id = aws_security_group.rds_postgres.id
  from_port                    = var.database_port
  ip_protocol                  = "tcp"
  to_port                      = var.database_port
  description                  = "Allow ECS services to reach private PostgreSQL only"
}

resource "aws_vpc_security_group_ingress_rule" "rds_from_ecs" {
  security_group_id            = aws_security_group.rds_postgres.id
  referenced_security_group_id = aws_security_group.ecs_service.id
  from_port                    = var.database_port
  ip_protocol                  = "tcp"
  to_port                      = var.database_port
  description                  = "Allow PostgreSQL ingress only from the ECS service security group"
}

resource "aws_vpc_security_group_egress_rule" "ecs_to_redis" {
  count = var.enable_redis ? 1 : 0

  security_group_id            = aws_security_group.ecs_service.id
  referenced_security_group_id = aws_security_group.redis_cache[0].id
  from_port                    = var.redis_port
  ip_protocol                  = "tcp"
  to_port                      = var.redis_port
  description                  = "Allow ECS services to reach private Redis only when enabled"
}

resource "aws_vpc_security_group_ingress_rule" "redis_from_ecs" {
  count = var.enable_redis ? 1 : 0

  security_group_id            = aws_security_group.redis_cache[0].id
  referenced_security_group_id = aws_security_group.ecs_service.id
  from_port                    = var.redis_port
  ip_protocol                  = "tcp"
  to_port                      = var.redis_port
  description                  = "Allow Redis ingress only from the ECS service security group"
}
