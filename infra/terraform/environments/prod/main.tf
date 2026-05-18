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
    log_retention_days                 = var.log_retention_days
    deletion_protection_enabled        = var.deletion_protection_enabled
    enable_redis                       = var.enable_redis
    service_desired_count_default      = var.service_desired_count_default
    ecs_service_count                  = length(var.ecs_services)
    ecs_listener_rules_enabled         = var.create_ecs_listener_rules
    load_balancer_https_enabled        = var.enable_load_balancer_https_listener
    load_balancer_access_logs_enabled  = var.load_balancer_access_logs_enabled
    load_balancer_deletion_protection  = var.load_balancer_deletion_protection_enabled
    rds_multi_az                       = var.rds_multi_az
    rds_backup_retention_days          = var.rds_backup_retention_days
    rds_deletion_protection_enabled    = var.rds_deletion_protection_enabled
    rds_managed_master_user_secret     = true
    rds_publicly_accessible_by_default = false
  }

  load_balancer_defaults = {
    internal                    = var.load_balancer_internal
    http_listener_port          = var.load_balancer_http_listener_port
    https_listener_enabled      = var.enable_load_balancer_https_listener
    https_listener_port         = var.load_balancer_https_listener_port
    https_certificate_supplied  = var.load_balancer_https_certificate_arn != null
    access_logs_enabled         = var.load_balancer_access_logs_enabled
    access_logs_bucket_supplied = var.load_balancer_access_logs_bucket != null
    deletion_protection_enabled = var.load_balancer_deletion_protection_enabled
  }

  rds_postgres_defaults = {
    database_name                         = var.rds_database_name
    engine_version                        = var.rds_engine_version
    instance_class                        = var.rds_instance_class
    port                                  = var.database_port
    allocated_storage_gib                 = var.rds_allocated_storage_gib
    max_allocated_storage_gib             = var.rds_max_allocated_storage_gib
    storage_type                          = var.rds_storage_type
    storage_encrypted                     = var.rds_storage_encrypted
    storage_kms_key_supplied              = var.rds_storage_kms_key_id != null
    multi_az                              = var.rds_multi_az
    backup_retention_days                 = var.rds_backup_retention_days
    deletion_protection_enabled           = var.rds_deletion_protection_enabled
    skip_final_snapshot                   = var.rds_skip_final_snapshot
    delete_automated_backups              = var.rds_delete_automated_backups
    enabled_cloudwatch_logs_exports       = var.rds_enabled_cloudwatch_logs_exports
    enhanced_monitoring_interval_seconds  = var.rds_monitoring_interval
    enhanced_monitoring_role_supplied     = var.rds_monitoring_role_arn != null
    performance_insights_enabled          = var.rds_performance_insights_enabled
    performance_insights_retention_period = var.rds_performance_insights_enabled ? var.rds_performance_insights_retention_period : null
    managed_master_user_password          = true
    master_user_secret_kms_key_supplied   = var.rds_master_user_secret_kms_key_id != null
    publicly_accessible                   = false
  }

  security_group_defaults = {
    alb_ingress_cidrs = var.alb_ingress_cidrs
    alb_ingress_ports = var.alb_ingress_ports
    service_port      = var.service_port
    database_port     = var.database_port
    enable_redis      = var.enable_redis
    redis_port        = var.redis_port
  }

  iam_defaults = {
    execution_secret_reference_arns = var.execution_secret_reference_arns
    execution_ssm_parameter_arns    = var.execution_ssm_parameter_arns
    execution_kms_key_arns          = var.execution_kms_key_arns
    task_secret_reference_arns      = var.task_secret_reference_arns
    task_ssm_parameter_arns         = var.task_ssm_parameter_arns
    task_kms_key_arns               = var.task_kms_key_arns
  }

  ecs_service_defaults = {
    cluster_name           = "${local.name_prefix}-ecs-cluster"
    service_names          = sort(keys(var.ecs_services))
    listener_rules_enabled = var.create_ecs_listener_rules
    listener_arn_source    = var.ecs_listener_arn == null ? "module.load_balancer.http_listener_arn" : "ecs_listener_arn_override"
  }

  planned_module_contract = {
    network         = "implemented-ticket-004"
    security_groups = "implemented-ticket-005"
    iam             = "implemented-ticket-006"
    ecs_service     = "implemented-ticket-007"
    load_balancer   = "implemented-ticket-008"
    rds_postgres    = "implemented-ticket-009"
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

module "iam" {
  source = "../../modules/iam"

  name_prefix                     = local.name_prefix
  environment                     = local.environment
  execution_secret_reference_arns = var.execution_secret_reference_arns
  execution_ssm_parameter_arns    = var.execution_ssm_parameter_arns
  execution_kms_key_arns          = var.execution_kms_key_arns
  task_secret_reference_arns      = var.task_secret_reference_arns
  task_ssm_parameter_arns         = var.task_ssm_parameter_arns
  task_kms_key_arns               = var.task_kms_key_arns
  common_tags                     = local.common_tags
}

module "load_balancer" {
  source = "../../modules/load-balancer"

  name_prefix                = local.name_prefix
  environment                = local.environment
  public_subnet_ids          = module.network.public_subnet_ids
  security_group_ids         = [module.security_groups.load_balancer_security_group_id]
  internal                   = var.load_balancer_internal
  enable_deletion_protection = var.load_balancer_deletion_protection_enabled
  http_listener_port         = var.load_balancer_http_listener_port
  enable_https_listener      = var.enable_load_balancer_https_listener
  https_listener_port        = var.load_balancer_https_listener_port
  https_certificate_arn      = var.load_balancer_https_certificate_arn
  https_ssl_policy           = var.load_balancer_https_ssl_policy
  access_logs_enabled        = var.load_balancer_access_logs_enabled
  access_logs_bucket         = var.load_balancer_access_logs_bucket
  access_logs_prefix         = var.load_balancer_access_logs_prefix
  common_tags                = local.common_tags
}

module "rds_postgres" {
  source = "../../modules/rds-postgres"

  name_prefix        = local.name_prefix
  environment        = local.environment
  private_subnet_ids = module.network.private_subnet_ids
  security_group_ids = [module.security_groups.rds_postgres_security_group_id]

  database_name                         = var.rds_database_name
  master_username                       = var.rds_master_username
  engine_version                        = var.rds_engine_version
  instance_class                        = var.rds_instance_class
  port                                  = var.database_port
  allocated_storage_gib                 = var.rds_allocated_storage_gib
  max_allocated_storage_gib             = var.rds_max_allocated_storage_gib
  storage_type                          = var.rds_storage_type
  storage_encrypted                     = var.rds_storage_encrypted
  storage_kms_key_id                    = var.rds_storage_kms_key_id
  master_user_secret_kms_key_id         = var.rds_master_user_secret_kms_key_id
  multi_az                              = var.rds_multi_az
  backup_retention_days                 = var.rds_backup_retention_days
  preferred_backup_window               = var.rds_preferred_backup_window
  preferred_maintenance_window          = var.rds_preferred_maintenance_window
  deletion_protection                   = var.rds_deletion_protection_enabled
  skip_final_snapshot                   = var.rds_skip_final_snapshot
  final_snapshot_identifier             = var.rds_final_snapshot_identifier
  delete_automated_backups              = var.rds_delete_automated_backups
  copy_tags_to_snapshot                 = var.rds_copy_tags_to_snapshot
  auto_minor_version_upgrade            = var.rds_auto_minor_version_upgrade
  apply_immediately                     = var.rds_apply_immediately
  enabled_cloudwatch_logs_exports       = var.rds_enabled_cloudwatch_logs_exports
  monitoring_interval                   = var.rds_monitoring_interval
  monitoring_role_arn                   = var.rds_monitoring_role_arn
  performance_insights_enabled          = var.rds_performance_insights_enabled
  performance_insights_kms_key_id       = var.rds_performance_insights_kms_key_id
  performance_insights_retention_period = var.rds_performance_insights_retention_period
  ca_cert_identifier                    = var.rds_ca_cert_identifier
  common_tags                           = local.common_tags
}

resource "aws_ecs_cluster" "platform" {
  name = local.ecs_service_defaults.cluster_name

  tags = merge(local.common_tags, {
    Name      = local.ecs_service_defaults.cluster_name
    Component = "ecs-cluster"
  })
}

module "ecs_services" {
  source   = "../../modules/ecs-service"
  for_each = var.ecs_services

  name_prefix             = local.name_prefix
  environment             = local.environment
  service_name            = each.key
  aws_region              = var.aws_region
  vpc_id                  = module.network.vpc_id
  cluster_arn             = aws_ecs_cluster.platform.arn
  cluster_name            = aws_ecs_cluster.platform.name
  private_subnet_ids      = module.network.private_subnet_ids
  security_group_ids      = [module.security_groups.ecs_service_security_group_id]
  task_execution_role_arn = module.iam.ecs_task_execution_role_arn
  task_role_arn           = module.iam.ecs_task_role_arn

  container_image    = each.value.image
  container_port     = each.value.container_port
  cpu                = each.value.cpu
  memory             = each.value.memory
  desired_count      = each.value.desired_count
  log_retention_days = var.log_retention_days
  health_check_path  = each.value.health_check_path
  environment_variables = merge(
    {
      APP_ENV      = local.environment
      SERVICE_NAME = each.key
    },
    each.value.environment_variables
  )
  secret_references = each.value.secret_references

  create_listener_rule        = var.create_ecs_listener_rules
  listener_arn                = var.ecs_listener_arn == null ? module.load_balancer.http_listener_arn : var.ecs_listener_arn
  listener_rule_priority      = each.value.listener_rule_priority
  listener_rule_path_patterns = each.value.listener_rule_path_patterns

  enable_autoscaling              = each.value.enable_autoscaling
  autoscaling_min_capacity        = each.value.autoscaling_min_capacity
  autoscaling_max_capacity        = each.value.autoscaling_max_capacity
  autoscaling_cpu_target_value    = each.value.autoscaling_cpu_target_value
  autoscaling_memory_target_value = each.value.autoscaling_memory_target_value

  common_tags = local.common_tags
}
