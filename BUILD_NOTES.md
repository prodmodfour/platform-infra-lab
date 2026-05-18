# BUILD_NOTES.md

## Current state

Tickets 000 through 011 are complete. The repository now has the public-safe skeleton, validation guardrails, Terraform conventions, dev/prod Terraform environment roots, shared AWS network module, shared security-groups module, shared IAM module, shared load-balancer module, ECS/Fargate service module wired for the three portfolio demo services, private RDS PostgreSQL module, optional private Redis/Valkey-style cache module, and CloudWatch observability module wired into both environments.

The next run should start with the lowest-numbered TODO ticket in `BUILD_TICKETS.md`.

## Quality gates

- `bash scripts/check-terraform.sh` — passed.
  - Ran `terraform fmt -recursive -check`, `terraform init -backend=false`, and `terraform validate` for both `dev` and `prod` using a temporary copy of the Terraform tree.
- `bash scripts/quality-gate.sh` — passed.
  - Guardrails for shell syntax, public safety, no Terraform state/plan/real tfvars files, no secret-like files, no cloud mutation automation, required Terraform module structure, observability module wiring, and Terraform validation passed.

## Public-safety notes

This project is an independent public portfolio project.

Do not add employer code, private data, internal URLs, credentials, real cloud account IDs, screenshots, non-public architecture, or anything implying employer endorsement.

Do not commit Terraform state, real tfvars, plan files, cloud credentials, SSH keys, kubeconfig files, or `.env` files with secrets.

Do not add automated cloud mutation commands such as `terraform apply`, `terraform destroy`, `terraform import`, or cloud CLI deploy commands.

## Latest cycle notes

Changed in ticket 011:

- Added `infra/terraform/modules/observability/` with `main.tf`, `variables.tf`, `outputs.tf`, and `README.md`.
- Modeled a CloudWatch observability layer with:
  - one CloudWatch dashboard per environment
  - ALB 5xx alarm using the ApplicationELB `LoadBalancer` ARN-suffix dimension
  - per-service unhealthy-target alarms using `LoadBalancer` and `TargetGroup` ARN-suffix dimensions
  - per-service ECS CPU and memory alarms using cluster and service-name dimensions
  - RDS PostgreSQL CPU and low-free-storage alarms using the DB instance identifier
  - dashboard widgets for ALB errors/latency, target health, ECS CPU/memory, RDS health, and recent ECS service logs
  - ECS log group naming convention output for `/aws/ecs/<name_prefix>/<service-name>`
  - empty alarm action lists by default so no real SNS topic, incident-routing ARN, webhook, or account-specific routing detail is committed
- Added load-balancer and ECS service outputs needed for CloudWatch metric dimensions:
  - `load_balancer_arn_suffix`
  - `target_group_arn_suffix`
- Wired the observability module into both `infra/terraform/environments/dev/` and `infra/terraform/environments/prod/`.
- Added environment variables and public-safe `terraform.tfvars.example` values for dashboard period, alarm period, ALB thresholds, ECS CPU/memory thresholds, RDS CPU/free-storage thresholds, and empty alarm action lists.
- Added environment outputs for observability defaults, CloudWatch dashboard name/ARN, alarm names, alarm summary, dashboard summary, and log group naming convention.
- Updated Terraform documentation, module READMEs, environment READMEs, architecture notes, operations/runbook placeholders, deployment/rollback placeholders, security notes, review guide, cost notes, and root README for the observability layer.
- Updated `scripts/quality-gate.sh` to require the observability module files and sanity-check observability wiring in both environments.
- Marked ticket 011 as DONE in `BUILD_TICKETS.md`.

Limitations:

- Alarm thresholds are illustrative review defaults and must be tuned against real service baselines before production use.
- Alarm action lists are intentionally empty in committed examples; real paging, SNS topics, or incident-routing targets remain user-owned and must stay outside this public repo.
- The module covers shared ALB, ECS, and RDS CloudWatch signals; Redis/ElastiCache alarms, custom application metrics, traces, SLO burn-rate alarms, and business metrics remain future hardening work.
- Dashboard log widgets reference ECS service log groups but do not solve log redaction, retention policy, sensitive-data handling, or log-reader access controls.
- Observability resources can create CloudWatch costs if manually provisioned; exact prices are not claimed because costs change.
- GitHub Actions CI is still deferred to ticket 014.

## Next recommended ticket

Ticket 012.
