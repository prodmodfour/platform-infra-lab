# Review Guide

This guide helps hiring reviewers inspect `platform-infra-lab` quickly. The project is an independent public portfolio lab: it shows AWS/Terraform platform engineering patterns without employer details, real cloud account data, application source code, Terraform state, or automated cloud deployment.

Start with this guide if you want to understand what to look at first, how much depth to spend, and how this infrastructure lab complements the three backend service examples.

## Suggested 10-minute review path

Use this path for a fast signal check:

1. **Portfolio framing** — skim the root [`README.md`](../README.md) for the safety model, architecture themes, and quick validation command.
2. **Architecture shape** — read [`docs/architecture.md`](architecture.md) and the public-safe [`AWS container platform diagram`](diagrams/aws-container-platform.md) to see the ALB, private ECS services, RDS, Redis, IAM, secret-reference, and CloudWatch flow.
3. **Environment separation** — compare [`dev`](../infra/terraform/environments/dev/) and [`prod`](../infra/terraform/environments/prod/) environment roots, especially `main.tf`, `variables.tf`, `outputs.tf`, and `terraform.tfvars.example`.
4. **Core platform modules** — inspect [`network`](../infra/terraform/modules/network/), [`security-groups`](../infra/terraform/modules/security-groups/), [`load-balancer`](../infra/terraform/modules/load-balancer/), and [`ecs-service`](../infra/terraform/modules/ecs-service/) for the request path from public ALB to private Fargate tasks.
5. **Safety posture** — skim [`scripts/quality-gate.sh`](../scripts/quality-gate.sh), [`scripts/check-public-safety.sh`](../scripts/check-public-safety.sh), [`scripts/check-no-cloud-mutations.sh`](../scripts/check-no-cloud-mutations.sh), and the validation-only [`GitHub Actions workflow`](../.github/workflows/ci.yml).

Expected quick takeaway: this repo is designed to be reviewed as infrastructure code, not run as a one-click deployer.

## Suggested 30-minute review path

Use this path for a deeper portfolio review:

| Step | What to inspect | Why it matters |
| --- | --- | --- |
| 1 | [`README.md`](../README.md), [`docs/security.md`](security.md), and [`docs/cost-notes.md`](cost-notes.md) | Confirms public-safety, cloud-safety, cost-awareness, and validation-only posture. |
| 2 | [`infra/terraform/environments/README.md`](../infra/terraform/environments/README.md), `dev`, and `prod` roots | Shows environment separation while reusing the same module set. |
| 3 | [`network`](../infra/terraform/modules/network/) and [`security-groups`](../infra/terraform/modules/security-groups/) modules | Shows VPC layout, public/private subnet intent, and traffic boundaries. |
| 4 | [`load-balancer`](../infra/terraform/modules/load-balancer/) and [`ecs-service`](../infra/terraform/modules/ecs-service/) modules | Shows ALB listener pattern, target groups, health checks, private task placement, logs, and autoscaling inputs. |
| 5 | [`iam`](../infra/terraform/modules/iam/) and [`secrets-manager-references`](../infra/terraform/modules/secrets-manager-references/) modules plus [`docs/secrets.md`](secrets.md) | Shows task execution role versus task role and secret references instead of committed values. |
| 6 | [`rds-postgres`](../infra/terraform/modules/rds-postgres/) and [`redis-cache`](../infra/terraform/modules/redis-cache/) modules | Shows private PostgreSQL and optional private Redis/ElastiCache patterns with backup, deletion-protection, and cache enablement trade-offs. |
| 7 | [`observability`](../infra/terraform/modules/observability/) module plus [`docs/operations.md`](operations.md) and [`docs/runbook.md`](runbook.md) | Shows dashboards, alarms, logs, and operational response thinking. |
| 8 | [`docs/deployment.md`](deployment.md) and [`docs/rollback.md`](rollback.md) | Shows validation-first deployment review, service image update flow, and rollback scenarios. |
| 9 | [`docs/service-examples.md`](service-examples.md) and environment `terraform.tfvars.example` files | Shows how the three placeholder backend services are represented without copying app code. |
| 10 | Run `bash scripts/quality-gate.sh` locally if time permits | Verifies repository guardrails, Markdown links, Terraform formatting, and Terraform validation when Terraform is installed. |

## Important modules to inspect

| Module | Review focus |
| --- | --- |
| [`infra/terraform/modules/network`](../infra/terraform/modules/network/) | VPC, public subnets, private subnets, route-table intent, internet gateway, optional NAT gateway, tags, and subnet/VPC outputs. |
| [`infra/terraform/modules/security-groups`](../infra/terraform/modules/security-groups/) | Public internet to ALB only, ALB to ECS only, ECS to PostgreSQL/Redis only, and no public database/cache ingress. |
| [`infra/terraform/modules/load-balancer`](../infra/terraform/modules/load-balancer/) | Public Application Load Balancer, HTTP listener, optional HTTPS variables, access-log placeholder pattern, and listener outputs. |
| [`infra/terraform/modules/ecs-service`](../infra/terraform/modules/ecs-service/) | Task definition, ECS service, target group, listener rule, health checks, logs, environment variables, secret references, and autoscaling. |
| [`infra/terraform/modules/iam`](../infra/terraform/modules/iam/) | ECS task execution role, application task role, scoped secret-reference policies, and least-privilege intent. |
| [`infra/terraform/modules/secrets-manager-references`](../infra/terraform/modules/secrets-manager-references/) | Metadata-only Secrets Manager containers without secret values or `aws_secretsmanager_secret_version` resources. |
| [`infra/terraform/modules/rds-postgres`](../infra/terraform/modules/rds-postgres/) | Private RDS PostgreSQL subnet group, no public accessibility, backups, storage, deletion protection, and managed secret reference output. |
| [`infra/terraform/modules/redis-cache`](../infra/terraform/modules/redis-cache/) | Optional private cache, enable/disable flag, encryption settings, snapshots, replica/Multi-AZ variables, and cost trade-offs. |
| [`infra/terraform/modules/observability`](../infra/terraform/modules/observability/) | CloudWatch dashboard, ALB alarms, ECS CPU/memory alarms, RDS alarms, log-group naming, and alarm-action placeholders. |

## Important docs to inspect

| Document | What it demonstrates |
| --- | --- |
| [`docs/architecture.md`](architecture.md) | Request flow, deployment flow, environment separation, IAM roles, secret references, and component placement. |
| [`docs/diagrams/aws-container-platform.md`](diagrams/aws-container-platform.md) | Mermaid/text diagrams for the container platform and deployment flow. |
| [`docs/service-examples.md`](service-examples.md) | Review-friendly mapping for `carbon-platform-api`, `job-runner-platform`, and `multi-tenant-saas-api`. |
| [`docs/deployment.md`](deployment.md) | Validation-first deployment checklist, manual plan review, image update flow, promotion approach, and migration considerations. |
| [`docs/rollback.md`](rollback.md) | Rollback paths for bad images, health-check failures, config/secret mistakes, database issues, Redis issues, and ALB routing issues. |
| [`docs/operations.md`](operations.md) and [`docs/runbook.md`](runbook.md) | Health checks, logs, metrics, alarms, incident triage, cost cleanup, and access review. |
| [`docs/security.md`](security.md) | Public-safety, no-state/no-secret posture, IAM separation, private data tiers, validation-only CI, and production hardening gaps. |
| [`docs/cost-notes.md`](cost-notes.md) | Qualitative cost drivers, resources that continue billing, dev/prod trade-offs, and cleanup guidance. |
| [`docs/secrets.md`](secrets.md) | Secret references, value ownership outside the repo, and rotation considerations. |
| [`infra/terraform/README.md`](../infra/terraform/README.md) | Terraform repository conventions, backend guidance, module interface expectations, and validation-only workflow. |

## What the project demonstrates

This project is intended to demonstrate backend/platform/SRE judgment through:

- Reviewable Terraform module design with explicit variables, outputs, README files, and environment roots.
- AWS container platform architecture using ECS/Fargate behind an Application Load Balancer.
- Private service placement with public ingress constrained to the ALB edge.
- Private PostgreSQL/RDS and optional private Redis/ElastiCache patterns.
- IAM separation between ECS task execution and application runtime roles.
- Secret-management patterns that use references rather than committed values.
- Health checks, target groups, CloudWatch logs, dashboards, and alarms.
- Dev/prod environment separation and visible production-intent trade-offs.
- Validation-only CI and shell guardrails for public-safety, no state files, no real variable files, and no automated cloud mutation.
- Operational documentation for deployment review, rollback, incident triage, cost cleanup, and access review.

## What is intentionally out of scope

The repo deliberately does not include:

- Application source code or another web service implementation.
- One-click deployment, automatic provisioning, automatic teardown, Terraform import automation, or CI-driven cloud mutation.
- Real account IDs, real backend buckets, real hostnames, real service images, private URLs, or employer-specific architecture.
- Terraform state, generated plan files, real `.tfvars`, credentials, SSH keys, kubeconfigs, or `.env` secret files.
- Production-ready TLS/DNS/WAF configuration, private egress strategy, image provenance, paging routes, compliance controls, or incident-management integrations.
- Database migration automation, secret rotation automation, backup restore drills, or disaster recovery implementation.
- Exact current AWS pricing claims.

These boundaries are intentional so the repository stays safe to publish while still demonstrating deployability and operational thinking.

## How it complements the three backend repos

When reviewed alongside the three backend portfolio services, this lab provides the platform layer those services would need in AWS:

| Backend service example | How this infrastructure lab complements it |
| --- | --- |
| `carbon-platform-api` | Shows how a data-backed API can run as a private ECS service behind the ALB, use a PostgreSQL connection secret reference, emit logs, and participate in target-group health checks. |
| `job-runner-platform` | Shows how a worker-oriented backend can be represented as a managed ECS service with health checks, logs, autoscaling inputs, secret references, and optional private Redis/Valkey coordination patterns. |
| `multi-tenant-saas-api` | Shows how a tenant-aware API can sit behind path-based ALB routing, use private PostgreSQL and optional cache patterns, inject JWT/database secret references, and surface operational signals. |

The backend repositories can focus on application design, API behavior, testing, and domain logic. `platform-infra-lab` focuses on the surrounding AWS platform concerns: networking, IAM, service deployment, load balancing, stateful dependencies, observability, validation, rollback, security boundaries, and cost awareness.

No backend source code is copied here. The fake image names and placeholder service profiles are intentionally public-safe review artifacts.
