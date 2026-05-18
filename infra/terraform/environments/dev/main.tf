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

  security_group_defaults = {
    alb_ingress_cidrs = var.alb_ingress_cidrs
    alb_ingress_ports = var.alb_ingress_ports
    service_port      = var.service_port
    database_port     = var.database_port
    enable_redis      = var.enable_redis
    redis_port        = var.redis_port
  }

  planned_module_contract = {
    network         = "implemented-ticket-004"
    security_groups = "implemented-ticket-005"
    iam             = "ticket-006"
    ecs_service     = "ticket-007"
    load_balancer   = "ticket-008"
    rds_postgres    = "ticket-009"
    redis_cache     = "ticket-010"
    observability   = "ticket-011"
  }
}

module "network" {
  source = "../../modules/network"

  name_prefix          = local.name_prefix
  environment          = local.environment
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  enable_nat_gateway   = var.enable_nat_gateway
  common_tags          = local.common_tags
}

module "security_groups" {
  source = "../../modules/security-groups"

  name_prefix       = local.name_prefix
  environment       = local.environment
  vpc_id            = module.network.vpc_id
  alb_ingress_cidrs = var.alb_ingress_cidrs
  alb_ingress_ports = var.alb_ingress_ports
  service_port      = var.service_port
  database_port     = var.database_port
  enable_redis      = var.enable_redis
  redis_port        = var.redis_port
  common_tags       = local.common_tags
}
