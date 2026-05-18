#!/usr/bin/env bash
set -euo pipefail

require_path() {
  local path="$1"
  if [[ ! -e "$path" ]]; then
    echo "Missing required bootstrap path: $path" >&2
    exit 1
  fi
}

echo "== bootstrap structure checks =="
required_paths=(
  README.md
  .gitignore
  .github/workflows/ci.yml
  AGENTS.md
  BUILD_TICKETS.md
  BUILD_NOTES.md
  scripts
  scripts/check-doc-links.sh
  docs
  docs/deployment.md
  docs/rollback.md
  docs/operations.md
  docs/runbook.md
  docs/cost-notes.md
  docs/security.md
  docs/review-guide.md
  docs/secrets.md
  docs/service-examples.md
  docs/decisions
  docs/decisions/0001-aws-ecs-fargate-as-container-platform.md
  docs/decisions/0002-terraform-modules-and-environments.md
  docs/decisions/0003-private-database-and-cache.md
  docs/decisions/0004-secrets-are-references-not-values.md
  docs/decisions/0005-validation-only-ci.md
  docs/diagrams
  docs/diagrams/aws-container-platform.md
  infra
  infra/terraform
  infra/terraform/README.md
  infra/terraform/modules
  infra/terraform/modules/README.md
  infra/terraform/modules/ecs-service/main.tf
  infra/terraform/modules/ecs-service/variables.tf
  infra/terraform/modules/ecs-service/outputs.tf
  infra/terraform/modules/ecs-service/README.md
  infra/terraform/modules/iam/main.tf
  infra/terraform/modules/iam/variables.tf
  infra/terraform/modules/iam/outputs.tf
  infra/terraform/modules/iam/README.md
  infra/terraform/modules/load-balancer/main.tf
  infra/terraform/modules/load-balancer/variables.tf
  infra/terraform/modules/load-balancer/outputs.tf
  infra/terraform/modules/load-balancer/README.md
  infra/terraform/modules/network/main.tf
  infra/terraform/modules/network/variables.tf
  infra/terraform/modules/network/outputs.tf
  infra/terraform/modules/network/README.md
  infra/terraform/modules/rds-postgres/main.tf
  infra/terraform/modules/rds-postgres/variables.tf
  infra/terraform/modules/rds-postgres/outputs.tf
  infra/terraform/modules/rds-postgres/README.md
  infra/terraform/modules/redis-cache/main.tf
  infra/terraform/modules/redis-cache/variables.tf
  infra/terraform/modules/redis-cache/outputs.tf
  infra/terraform/modules/redis-cache/README.md
  infra/terraform/modules/observability/main.tf
  infra/terraform/modules/observability/variables.tf
  infra/terraform/modules/observability/outputs.tf
  infra/terraform/modules/observability/README.md
  infra/terraform/modules/secrets-manager-references/main.tf
  infra/terraform/modules/secrets-manager-references/variables.tf
  infra/terraform/modules/secrets-manager-references/outputs.tf
  infra/terraform/modules/secrets-manager-references/README.md
  infra/terraform/modules/security-groups/main.tf
  infra/terraform/modules/security-groups/variables.tf
  infra/terraform/modules/security-groups/outputs.tf
  infra/terraform/modules/security-groups/README.md
  infra/terraform/environments
  infra/terraform/environments/README.md
  infra/terraform/environments/dev/providers.tf
  infra/terraform/environments/dev/main.tf
  infra/terraform/environments/dev/variables.tf
  infra/terraform/environments/dev/outputs.tf
  infra/terraform/environments/dev/backend.example.tf
  infra/terraform/environments/dev/terraform.tfvars.example
  infra/terraform/environments/dev/README.md
  infra/terraform/environments/prod/providers.tf
  infra/terraform/environments/prod/main.tf
  infra/terraform/environments/prod/variables.tf
  infra/terraform/environments/prod/outputs.tf
  infra/terraform/environments/prod/backend.example.tf
  infra/terraform/environments/prod/terraform.tfvars.example
  infra/terraform/environments/prod/README.md
)

for path in "${required_paths[@]}"; do
  require_path "$path"
done

echo "== README framing checks =="
grep -q "^# platform-infra-lab" README.md
grep -qi "independent public portfolio" README.md
grep -qi "AWS/Terraform" README.md
grep -qi "no automatic cloud deployment" README.md
grep -qi "no committed secrets" README.md
grep -qi "No Terraform state" README.md
grep -qi "manual apply.*can incur" README.md
grep -qi "backend/platform/SRE" README.md
required_readme_headings=(
  "Portfolio framing"
  "Public-safety constraints"
  "Cloud-safety constraints"
  "Implemented scope"
  "Out of scope"
  "Requirements"
  "Quick start validation"
  "Repository structure"
  "Architecture summary"
  "Terraform module summary"
  "Environment summary"
  "CI and quality gate summary"
  "Deployment and rollback docs"
  "Cost and security docs"
  "Suggested review path"
  "Limitations"
)
for heading in "${required_readme_headings[@]}"; do
  grep -q "^## $heading" README.md
done
for readme_term in "Application Load Balancer" "ECS/Fargate" "RDS" "Redis" "Secrets Manager" "CloudWatch"; do
  grep -qi "$readme_term" README.md
done
for readme_link in \
  "docs/architecture.md" \
  "docs/deployment.md" \
  "docs/rollback.md" \
  "docs/cost-notes.md" \
  "docs/security.md" \
  "docs/review-guide.md" \
  "infra/terraform/modules/network/README.md" \
  "infra/terraform/modules/ecs-service/README.md" \
  "infra/terraform/environments/dev/README.md" \
  "infra/terraform/environments/prod/README.md"; do
  grep -q "$readme_link" README.md
done

echo "== CI workflow checks =="
grep -q 'hashicorp/setup-terraform@v' .github/workflows/ci.yml
grep -q 'bash scripts/quality-gate.sh' .github/workflows/ci.yml
grep -qi 'pull_request' .github/workflows/ci.yml
grep -qi 'workflow_dispatch' .github/workflows/ci.yml

echo "== Terraform convention documentation checks =="
grep -qi "backend.example.tf" infra/terraform/README.md
grep -qi "terraform.tfvars.example" infra/terraform/README.md
grep -qi "Never commit Terraform state" infra/terraform/README.md
grep -qi "validation-only" infra/terraform/README.md
grep -qi "manual apply" infra/terraform/README.md
grep -qi "Module interface conventions" infra/terraform/modules/README.md
grep -qi "common_tags" infra/terraform/modules/README.md
grep -qi "Backend examples" infra/terraform/environments/README.md
grep -qi "terraform.tfvars.example" infra/terraform/environments/README.md
grep -qi "Validation-only workflow" infra/terraform/environments/README.md

echo "== Terraform environment skeleton checks =="
for env in dev prod; do
  grep -q 'backend "s3"' "infra/terraform/environments/$env/backend.example.tf"
  grep -qi "public-safe" "infra/terraform/environments/$env/README.md"
  grep -qi "terraform.tfvars.example" "infra/terraform/environments/$env/README.md"
  grep -q "environment_name.*$env" "infra/terraform/environments/$env/terraform.tfvars.example"
done

echo "== Terraform network module checks =="
grep -q 'resource "aws_vpc"' infra/terraform/modules/network/main.tf
grep -q 'resource "aws_subnet" "public"' infra/terraform/modules/network/main.tf
grep -q 'resource "aws_subnet" "private"' infra/terraform/modules/network/main.tf
grep -q 'resource "aws_nat_gateway"' infra/terraform/modules/network/main.tf
grep -qi "Public and private subnet intent" infra/terraform/modules/network/README.md
grep -qi "NAT gateway" infra/terraform/modules/network/README.md
for env in dev prod; do
  grep -q 'module "network"' "infra/terraform/environments/$env/main.tf"
  grep -q 'output "vpc_id"' "infra/terraform/environments/$env/outputs.tf"
done

echo "== Terraform IAM module checks =="
grep -q 'resource "aws_iam_role" "task_execution"' infra/terraform/modules/iam/main.tf
grep -q 'resource "aws_iam_role" "task"' infra/terraform/modules/iam/main.tf
grep -q 'AmazonECSTaskExecutionRolePolicy' infra/terraform/modules/iam/main.tf
grep -q 'resource "aws_iam_role_policy" "execution_secret_references"' infra/terraform/modules/iam/main.tf
grep -q 'resource "aws_iam_role_policy" "task_secret_references"' infra/terraform/modules/iam/main.tf
grep -qi "Task role versus execution role" infra/terraform/modules/iam/README.md
grep -qi "Secret references, not values" infra/terraform/modules/iam/README.md
grep -qi "Production review requirements" infra/terraform/modules/iam/README.md
for env in dev prod; do
  grep -q 'module "iam"' "infra/terraform/environments/$env/main.tf"
  grep -q 'output "ecs_task_execution_role_arn"' "infra/terraform/environments/$env/outputs.tf"
  grep -q 'execution_secret_reference_arns' "infra/terraform/environments/$env/terraform.tfvars.example"
done

echo "== Terraform Secrets Manager reference module checks =="
grep -q 'resource "aws_secretsmanager_secret" "ecs_execution"' infra/terraform/modules/secrets-manager-references/main.tf
if grep -R 'resource "aws_secretsmanager_secret_version"' infra/terraform >/dev/null; then
  echo "ERROR: secret value resources are not allowed in this public repo; use references only." >&2
  exit 1
fi
grep -qi "Secret references, not values" infra/terraform/modules/secrets-manager-references/README.md
grep -qi "Value ownership" infra/terraform/modules/secrets-manager-references/README.md
grep -qi "Rotation considerations" infra/terraform/modules/secrets-manager-references/README.md
grep -qi "created outside this public repository" docs/secrets.md
grep -qi "does not create.*aws_secretsmanager_secret_version" docs/secrets.md
for env in dev prod; do
  grep -q 'module "secrets_manager_references"' "infra/terraform/environments/$env/main.tf"
  grep -q 'module.secrets_manager_references.ecs_secret_references_by_service' "infra/terraform/environments/$env/main.tf"
  grep -q 'output "secrets_manager_metadata_summary"' "infra/terraform/environments/$env/outputs.tf"
  grep -q 'ecs_secret_definitions' "infra/terraform/environments/$env/terraform.tfvars.example"
  grep -q 'secrets_manager_kms_key_id              = null' "infra/terraform/environments/$env/terraform.tfvars.example"
done

echo "== Terraform load balancer module checks =="
grep -q 'resource "aws_lb" "this"' infra/terraform/modules/load-balancer/main.tf
grep -q 'resource "aws_lb_listener" "http"' infra/terraform/modules/load-balancer/main.tf
grep -q 'resource "aws_lb_listener" "https"' infra/terraform/modules/load-balancer/main.tf
grep -q 'dynamic "access_logs"' infra/terraform/modules/load-balancer/main.tf
grep -q 'output "http_listener_arn"' infra/terraform/modules/load-balancer/outputs.tf
grep -qi "Target group wiring pattern" infra/terraform/modules/load-balancer/README.md
grep -qi "HTTPS production requirement" infra/terraform/modules/load-balancer/README.md
grep -qi "database/cache stay private\|PostgreSQL/RDS and Redis/ElastiCache remain private" infra/terraform/modules/load-balancer/README.md
for env in dev prod; do
  grep -q 'module "load_balancer"' "infra/terraform/environments/$env/main.tf"
  grep -q 'module.load_balancer.http_listener_arn' "infra/terraform/environments/$env/main.tf"
  grep -q 'output "load_balancer_dns_name"' "infra/terraform/environments/$env/outputs.tf"
  grep -q 'output "load_balancer_http_listener_arn"' "infra/terraform/environments/$env/outputs.tf"
  grep -q 'create_ecs_listener_rules = true' "infra/terraform/environments/$env/terraform.tfvars.example"
  grep -q 'enable_load_balancer_https_listener       = false' "infra/terraform/environments/$env/terraform.tfvars.example"
done

echo "== Terraform RDS PostgreSQL module checks =="
grep -q 'resource "aws_db_subnet_group" "this"' infra/terraform/modules/rds-postgres/main.tf
grep -q 'resource "aws_db_instance" "this"' infra/terraform/modules/rds-postgres/main.tf
grep -q 'manage_master_user_password' infra/terraform/modules/rds-postgres/main.tf
grep -q 'publicly_accessible    = false' infra/terraform/modules/rds-postgres/main.tf
grep -q 'backup_retention_period' infra/terraform/modules/rds-postgres/main.tf
grep -q 'deletion_protection' infra/terraform/modules/rds-postgres/main.tf
grep -q 'master_user_secret_arn' infra/terraform/modules/rds-postgres/outputs.tf
grep -qi "Private database design" infra/terraform/modules/rds-postgres/README.md
grep -qi "Credentials and secret references" infra/terraform/modules/rds-postgres/README.md
grep -qi "Migration considerations" infra/terraform/modules/rds-postgres/README.md
grep -qi "Production hardening gaps" infra/terraform/modules/rds-postgres/README.md
for env in dev prod; do
  grep -q 'module "rds_postgres"' "infra/terraform/environments/$env/main.tf"
  grep -q 'module.security_groups.rds_postgres_security_group_id' "infra/terraform/environments/$env/main.tf"
  grep -q 'output "rds_postgres_endpoint"' "infra/terraform/environments/$env/outputs.tf"
  grep -q 'output "rds_postgres_master_user_secret_arn"' "infra/terraform/environments/$env/outputs.tf"
  grep -q 'rds_database_name' "infra/terraform/environments/$env/terraform.tfvars.example"
  grep -q 'rds_master_user_secret_kms_key_id         = null' "infra/terraform/environments/$env/terraform.tfvars.example"
done

echo "== Terraform Redis cache module checks =="
grep -q 'resource "aws_elasticache_subnet_group" "this"' infra/terraform/modules/redis-cache/main.tf
grep -q 'resource "aws_elasticache_replication_group" "this"' infra/terraform/modules/redis-cache/main.tf
grep -q 'count = var.enabled ? 1 : 0' infra/terraform/modules/redis-cache/main.tf
grep -q 'automatic_failover_enabled' infra/terraform/modules/redis-cache/main.tf
grep -q 'multi_az_enabled' infra/terraform/modules/redis-cache/main.tf
grep -q 'transit_encryption_enabled' infra/terraform/modules/redis-cache/main.tf
grep -q 'connection_reference_summary' infra/terraform/modules/redis-cache/outputs.tf
grep -qi "Optional cache use" infra/terraform/modules/redis-cache/README.md
grep -qi "Private access" infra/terraform/modules/redis-cache/README.md
grep -qi "Cost implications" infra/terraform/modules/redis-cache/README.md
grep -qi "Production hardening gaps" infra/terraform/modules/redis-cache/README.md
for env in dev prod; do
  grep -q 'module "redis_cache"' "infra/terraform/environments/$env/main.tf"
  grep -q 'module.security_groups.redis_cache_security_group_id' "infra/terraform/environments/$env/main.tf"
  grep -q 'output "redis_cache_replication_group_id"' "infra/terraform/environments/$env/outputs.tf"
  grep -q 'output "redis_cache_connection_reference_summary"' "infra/terraform/environments/$env/outputs.tf"
  grep -q 'redis_node_type' "infra/terraform/environments/$env/terraform.tfvars.example"
  grep -q 'redis_replica_count' "infra/terraform/environments/$env/terraform.tfvars.example"
done
grep -q 'enable_redis                  = false' infra/terraform/environments/dev/terraform.tfvars.example
grep -q 'enable_redis                  = true' infra/terraform/environments/prod/terraform.tfvars.example
grep -q 'redis_automatic_failover_enabled   = true' infra/terraform/environments/prod/terraform.tfvars.example

echo "== Terraform ECS service module checks =="
grep -q 'resource "aws_cloudwatch_log_group" "this"' infra/terraform/modules/ecs-service/main.tf
grep -q 'resource "aws_ecs_task_definition" "this"' infra/terraform/modules/ecs-service/main.tf
grep -q 'resource "aws_ecs_service" "this"' infra/terraform/modules/ecs-service/main.tf
grep -q 'resource "aws_lb_target_group" "this"' infra/terraform/modules/ecs-service/main.tf
grep -q 'resource "aws_lb_listener_rule" "this"' infra/terraform/modules/ecs-service/main.tf
grep -q 'resource "aws_appautoscaling_target" "desired_count"' infra/terraform/modules/ecs-service/main.tf
grep -q 'public.ecr.aws/example' infra/terraform/modules/ecs-service/variables.tf
grep -qi "Load-balancer wiring" infra/terraform/modules/ecs-service/README.md
grep -qi "Secret references" infra/terraform/modules/ecs-service/README.md
grep -qi "Autoscaling" infra/terraform/modules/ecs-service/README.md
for env in dev prod; do
  grep -q 'resource "aws_ecs_cluster" "platform"' "infra/terraform/environments/$env/main.tf"
  grep -q 'module "ecs_services"' "infra/terraform/environments/$env/main.tf"
  grep -q 'output "ecs_cluster_name"' "infra/terraform/environments/$env/outputs.tf"
  grep -q 'output "ecs_service_summaries"' "infra/terraform/environments/$env/outputs.tf"
  grep -q 'carbon-platform-api' "infra/terraform/environments/$env/terraform.tfvars.example"
  grep -q 'job-runner-platform' "infra/terraform/environments/$env/terraform.tfvars.example"
  grep -q 'multi-tenant-saas-api' "infra/terraform/environments/$env/terraform.tfvars.example"
  grep -q 'create_ecs_listener_rules = true' "infra/terraform/environments/$env/terraform.tfvars.example"
done

echo "== Service example catalog checks =="
grep -qi "Service examples" docs/service-examples.md
grep -qi "Expected health path" docs/service-examples.md
grep -qi "Placeholder environment variables" docs/service-examples.md
grep -qi "Secret references" docs/service-examples.md
grep -qi "Database/cache needs" docs/service-examples.md
grep -qi "Metrics/logging expectations" docs/service-examples.md
grep -qi "Deployment notes" docs/service-examples.md
for service in carbon-platform-api job-runner-platform multi-tenant-saas-api; do
  grep -q "$service" docs/service-examples.md
  grep -q "$service" docs/architecture.md
  grep -q "$service" README.md
  for env in dev prod; do
    grep -q "$service" "infra/terraform/environments/$env/variables.tf"
    grep -q "$service" "infra/terraform/environments/$env/terraform.tfvars.example"
  done
done
for env in dev prod; do
  grep -q 'variable "service_example_profiles"' "infra/terraform/environments/$env/variables.tf"
  grep -q 'service_example_catalog' "infra/terraform/environments/$env/main.tf"
  grep -q 'output "service_example_catalog"' "infra/terraform/environments/$env/outputs.tf"
  grep -q 'service_example_profiles = {' "infra/terraform/environments/$env/terraform.tfvars.example"
  grep -q 'expected_health_path' "infra/terraform/environments/$env/terraform.tfvars.example"
  grep -q 'placeholder_environment_keys' "infra/terraform/environments/$env/terraform.tfvars.example"
  grep -q 'database_requirement' "infra/terraform/environments/$env/terraform.tfvars.example"
  grep -q 'cache_requirement' "infra/terraform/environments/$env/terraform.tfvars.example"
  grep -q 'metrics_expectations' "infra/terraform/environments/$env/terraform.tfvars.example"
  grep -q 'logging_expectations' "infra/terraform/environments/$env/terraform.tfvars.example"
  grep -q 'deployment_notes' "infra/terraform/environments/$env/terraform.tfvars.example"
  grep -q 'public.ecr.aws/example/carbon-platform-api:demo' "infra/terraform/environments/$env/terraform.tfvars.example"
  grep -q 'public.ecr.aws/example/job-runner-platform:demo' "infra/terraform/environments/$env/terraform.tfvars.example"
  grep -q 'public.ecr.aws/example/multi-tenant-saas-api:demo' "infra/terraform/environments/$env/terraform.tfvars.example"
done

echo "== Terraform observability module checks =="
grep -q 'resource "aws_cloudwatch_dashboard" "this"' infra/terraform/modules/observability/main.tf
grep -q 'resource "aws_cloudwatch_metric_alarm" "alb_5xx"' infra/terraform/modules/observability/main.tf
grep -q 'resource "aws_cloudwatch_metric_alarm" "alb_unhealthy_targets"' infra/terraform/modules/observability/main.tf
grep -q 'resource "aws_cloudwatch_metric_alarm" "ecs_cpu"' infra/terraform/modules/observability/main.tf
grep -q 'resource "aws_cloudwatch_metric_alarm" "ecs_memory"' infra/terraform/modules/observability/main.tf
grep -q 'resource "aws_cloudwatch_metric_alarm" "rds_cpu"' infra/terraform/modules/observability/main.tf
grep -q 'resource "aws_cloudwatch_metric_alarm" "rds_free_storage"' infra/terraform/modules/observability/main.tf
grep -q 'log_group_naming_convention' infra/terraform/modules/observability/outputs.tf
grep -qi "Logs" infra/terraform/modules/observability/README.md
grep -qi "Metrics" infra/terraform/modules/observability/README.md
grep -qi "Alarms" infra/terraform/modules/observability/README.md
grep -qi "Dashboard" infra/terraform/modules/observability/README.md
grep -qi "Production gaps" infra/terraform/modules/observability/README.md
grep -q 'output "load_balancer_arn_suffix"' infra/terraform/modules/load-balancer/outputs.tf
grep -q 'output "target_group_arn_suffix"' infra/terraform/modules/ecs-service/outputs.tf
for env in dev prod; do
  grep -q 'module "observability"' "infra/terraform/environments/$env/main.tf"
  grep -q 'module.load_balancer.load_balancer_arn_suffix' "infra/terraform/environments/$env/main.tf"
  grep -q 'target_group_arn_suffix = service.target_group_arn_suffix' "infra/terraform/environments/$env/main.tf"
  grep -q 'output "cloudwatch_dashboard_name"' "infra/terraform/environments/$env/outputs.tf"
  grep -q 'output "cloudwatch_alarm_names"' "infra/terraform/environments/$env/outputs.tf"
  grep -q 'observability_alarm_actions             = \[\]' "infra/terraform/environments/$env/terraform.tfvars.example"
  grep -q 'alb_5xx_alarm_threshold' "infra/terraform/environments/$env/terraform.tfvars.example"
done

echo "== Terraform security group boundary checks =="
grep -q 'resource "aws_security_group" "load_balancer"' infra/terraform/modules/security-groups/main.tf
grep -q 'resource "aws_security_group" "ecs_service"' infra/terraform/modules/security-groups/main.tf
grep -q 'resource "aws_security_group" "rds_postgres"' infra/terraform/modules/security-groups/main.tf
grep -q 'resource "aws_security_group" "redis_cache"' infra/terraform/modules/security-groups/main.tf
grep -q 'resource "aws_vpc_security_group_ingress_rule" "ecs_from_alb"' infra/terraform/modules/security-groups/main.tf
grep -q 'resource "aws_vpc_security_group_ingress_rule" "rds_from_ecs"' infra/terraform/modules/security-groups/main.tf
grep -q 'resource "aws_vpc_security_group_ingress_rule" "redis_from_ecs"' infra/terraform/modules/security-groups/main.tf
grep -qi "PostgreSQL and Redis do not accept public ingress" infra/terraform/modules/security-groups/README.md
grep -qi "Traffic boundaries" infra/terraform/modules/security-groups/README.md
for env in dev prod; do
  grep -q 'module "security_groups"' "infra/terraform/environments/$env/main.tf"
  grep -q 'output "load_balancer_security_group_id"' "infra/terraform/environments/$env/outputs.tf"
  grep -q 'output "rds_postgres_security_group_id"' "infra/terraform/environments/$env/outputs.tf"
done

echo "== Architecture documentation checks =="
grep -qi "VPC/subnet layout" docs/architecture.md
grep -qi "ALB/public edge" docs/architecture.md
grep -qi "ECS private service placement" docs/architecture.md
grep -qi "RDS private placement" docs/architecture.md
grep -qi "Optional Redis private placement" docs/architecture.md
grep -qi "CloudWatch logs/metrics" docs/architecture.md
grep -qi "IAM roles" docs/architecture.md
grep -qi "Secret references" docs/architecture.md
grep -qi "Environment separation" docs/architecture.md
grep -qi "Request flow" docs/architecture.md
grep -qi "Deployment flow" docs/architecture.md
grep -q "flowchart" docs/diagrams/aws-container-platform.md
grep -q "sequenceDiagram" docs/diagrams/aws-container-platform.md
for architecture_term in "Application Load Balancer" "ECS" "RDS PostgreSQL" "Redis" "Secrets Manager" "CloudWatch"; do
  grep -q "$architecture_term" docs/diagrams/aws-container-platform.md
  grep -q "$architecture_term" docs/architecture.md
done

echo "== Deployment documentation checks =="
grep -qi "Pre-deploy checklist" docs/deployment.md
grep -qi "Required local tools" docs/deployment.md
grep -qi "Run validation" docs/deployment.md
grep -qi "Initialise Terraform manually" docs/deployment.md
grep -qi "Review a plan" docs/deployment.md
grep -qi "Manual apply warning" docs/deployment.md
grep -qi "Service image update flow" docs/deployment.md
grep -qi "Environment promotion approach" docs/deployment.md
grep -qi "Migration considerations" docs/deployment.md
grep -qi "Post-deploy checks" docs/deployment.md
grep -qi "optional, manual, user-owned, and can incur cost" docs/deployment.md
grep -q "terraform init -backend=false" docs/deployment.md
grep -q "terraform plan" docs/deployment.md

echo "== Rollback documentation checks =="
grep -qi "Decision tree" docs/rollback.md
grep -qi "Bad container image" docs/rollback.md
grep -qi "Failing health checks" docs/rollback.md
grep -qi "Failed ECS deployment" docs/rollback.md
grep -qi "Bad environment variable/secret reference" docs/rollback.md
grep -qi "Database migration issue" docs/rollback.md
grep -qi "RDS incident" docs/rollback.md
grep -qi "Redis/cache issue" docs/rollback.md
grep -qi "ALB/routing issue" docs/rollback.md
grep -qi "Verification steps" docs/rollback.md
grep -qi "Metrics/logs to check" docs/rollback.md
grep -qi "Communication notes" docs/rollback.md
grep -qi "Safety notes" docs/rollback.md
grep -qi "does not provide rollback scripts" docs/rollback.md

echo "== Operations documentation checks =="
grep -qi "Operational scope and safety posture" docs/operations.md
grep -qi "Health checks" docs/operations.md
grep -qi "Logs" docs/operations.md
grep -qi "Metrics" docs/operations.md
grep -qi "Alarms" docs/operations.md
grep -qi "Incident triage" docs/operations.md
grep -qi "RDS connectivity issue" docs/operations.md
grep -qi "Service crash loop" docs/operations.md
grep -qi "High 5xx rate" docs/operations.md
grep -qi "High latency" docs/operations.md
grep -qi "Database saturation" docs/operations.md
grep -qi "Redis unavailable" docs/operations.md
grep -qi "Deployment stuck" docs/operations.md
grep -qi "Cost cleanup" docs/operations.md
grep -qi "Access review" docs/operations.md
grep -qi "validation-only" docs/operations.md

echo "== Runbook documentation checks =="
grep -qi "Universal incident triage" docs/runbook.md
grep -qi "Health checks" docs/runbook.md
grep -qi "Logs" docs/runbook.md
grep -qi "Metrics" docs/runbook.md
grep -qi "Alarms" docs/runbook.md
grep -qi "RDS connectivity issue" docs/runbook.md
grep -qi "Service crash loop" docs/runbook.md
grep -qi "High 5xx rate" docs/runbook.md
grep -qi "High latency" docs/runbook.md
grep -qi "Database saturation" docs/runbook.md
grep -qi "Redis unavailable" docs/runbook.md
grep -qi "Deployment stuck" docs/runbook.md
grep -qi "Cost cleanup" docs/runbook.md
grep -qi "Access review" docs/runbook.md
grep -qi "Closeout checklist" docs/runbook.md

echo "== Cost documentation checks =="
grep -qi "Cost documentation scope" docs/cost-notes.md
grep -qi "Cost drivers" docs/cost-notes.md
grep -qi "NAT gateway cost implications" docs/cost-notes.md
grep -qi "RDS cost implications" docs/cost-notes.md
grep -qi "ALB cost implications" docs/cost-notes.md
grep -qi "ECS Fargate cost drivers" docs/cost-notes.md
grep -qi "CloudWatch log/metric costs" docs/cost-notes.md
grep -qi "Redis/ElastiCache costs" docs/cost-notes.md
grep -qi "Dev versus prod trade-offs" docs/cost-notes.md
grep -qi "Cleanup checklist" docs/cost-notes.md
grep -qi "How to avoid accidental spend" docs/cost-notes.md
grep -qi "optional, manual, user-owned, and can incur cost" docs/cost-notes.md
grep -qi "No exact current AWS prices are claimed" docs/cost-notes.md

echo "== Security documentation checks =="
grep -qi "Security scope and assumptions" docs/security.md
grep -qi "No committed secrets" docs/security.md
grep -qi "No Terraform state in git" docs/security.md
grep -qi "IAM role separation" docs/security.md
grep -qi "Least-privilege intent" docs/security.md
grep -qi "Private database/cache" docs/security.md
grep -qi "Public ALB boundary" docs/security.md
grep -qi "Secret reference pattern" docs/security.md
grep -qi "CI validation-only posture" docs/security.md
grep -qi "Manual apply warnings" docs/security.md
grep -qi "Production hardening gaps" docs/security.md
grep -qi "Access review checklist" docs/security.md
grep -qi "Threat model summary" docs/security.md
grep -qi "optional, manual, user-owned, and can incur cost" docs/security.md
grep -qi "validation-only" docs/security.md

echo "== Review guide documentation checks =="
grep -qi "Suggested 10-minute review path" docs/review-guide.md
grep -qi "Suggested 30-minute review path" docs/review-guide.md
grep -qi "Important modules to inspect" docs/review-guide.md
grep -qi "Important docs to inspect" docs/review-guide.md
grep -qi "What the project demonstrates" docs/review-guide.md
grep -qi "What is intentionally out of scope" docs/review-guide.md
grep -qi "How it complements the three backend repos" docs/review-guide.md
grep -q "carbon-platform-api" docs/review-guide.md
grep -q "job-runner-platform" docs/review-guide.md
grep -q "multi-tenant-saas-api" docs/review-guide.md
grep -q "infra/terraform/modules/ecs-service" docs/review-guide.md
grep -q "scripts/quality-gate.sh" docs/review-guide.md

echo "== ADR documentation checks =="
declare -A required_adr_terms=(
  [docs/decisions/0001-aws-ecs-fargate-as-container-platform.md]="ECS/Fargate"
  [docs/decisions/0002-terraform-modules-and-environments.md]="Terraform modules"
  [docs/decisions/0003-private-database-and-cache.md]="Private database"
  [docs/decisions/0004-secrets-are-references-not-values.md]="Secrets are references"
  [docs/decisions/0005-validation-only-ci.md]="Validation-only CI"
)
for adr in "${!required_adr_terms[@]}"; do
  grep -qi "^## Status" "$adr"
  grep -qi "^## Context" "$adr"
  grep -qi "^## Decision" "$adr"
  grep -qi "^## Consequences" "$adr"
  grep -qi "Accepted" "$adr"
  grep -qi "${required_adr_terms[$adr]}" "$adr"
done

grep -qi "optional, manual, user-owned" docs/decisions/0001-aws-ecs-fargate-as-container-platform.md
grep -qi "backend.example.tf" docs/decisions/0002-terraform-modules-and-environments.md
grep -qi "publicly_accessible.*false" docs/decisions/0003-private-database-and-cache.md
grep -qi "does not create.*aws_secretsmanager_secret_version" docs/decisions/0004-secrets-are-references-not-values.md
grep -qi "must not run Terraform apply" docs/decisions/0005-validation-only-ci.md

echo "== shell syntax checks =="
for script in scripts/*.sh; do
  [[ -e "$script" ]] || continue
  bash -n "$script"
done

echo "== guardrail self-tests =="
bash scripts/self-test-guardrails.sh

echo "== public-safety guardrail =="
bash scripts/check-public-safety.sh

echo "== Terraform state/secret-file guardrail =="
bash scripts/check-no-terraform-state.sh

echo "== cloud mutation guardrail =="
bash scripts/check-no-cloud-mutations.sh

echo "== documentation link sanity checks =="
bash scripts/check-doc-links.sh

echo "== Terraform validation =="
bash scripts/check-terraform.sh

echo "== quality gate passed =="
