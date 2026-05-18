locals {
  environment = var.environment_name
  name_prefix = "${var.project_name}-${local.environment}"

  common_tags = merge(
    {
      Project     = var.project_name
      Environment = local.environment
      ManagedBy   = "terraform"
      Repository  = "platform-infra-lab"
      Purpose     = "public-portfolio-demo"
    },
    var.additional_tags
  )

  network_defaults = {
    vpc_cidr             = var.vpc_cidr
    availability_zones   = var.availability_zones
    public_subnet_cidrs  = var.public_subnet_cidrs
    private_subnet_cidrs = var.private_subnet_cidrs
    enable_nat_gateway   = var.enable_nat_gateway
  }

  platform_defaults = {
    log_retention_days            = var.log_retention_days
    deletion_protection_enabled   = var.deletion_protection_enabled
    enable_redis                  = var.enable_redis
    service_desired_count_default = var.service_desired_count_default
  }

  planned_module_contract = {
    network         = "ticket-004"
    security_groups = "ticket-005"
    iam             = "ticket-006"
    ecs_service     = "ticket-007"
    load_balancer   = "ticket-008"
    rds_postgres    = "ticket-009"
    redis_cache     = "ticket-010"
    observability   = "ticket-011"
  }
}
