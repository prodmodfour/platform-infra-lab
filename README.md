# platform-infra-lab

`platform-infra-lab` is an independent public portfolio project for demonstrating platform engineering and infrastructure-as-code patterns with AWS and Terraform.

The repository is intentionally public-safe: it contains generic infrastructure examples, placeholder service names, and no employer/private system details.

## What this project is for

This lab is designed to show backend/platform/SRE skills through reviewable infrastructure code and operational documentation. The intended architecture will model containerised backend services on AWS using Terraform, including ECS/Fargate, load balancing, private data services, IAM boundaries, secret references, validation-only CI, observability, cost notes, and runbooks.

Reference services are placeholders only:

- `carbon-platform-api`
- `job-runner-platform`
- `multi-tenant-saas-api`

No application code is included here.

## Safety model

This repository must remain safe to publish and safe to review.

- Independent public portfolio project; no employer code or private architecture.
- AWS/Terraform is the primary infrastructure direction.
- No automatic cloud deployment is provided.
- No committed secrets, credentials, SSH keys, kubeconfigs, or private data.
- No Terraform state or generated plan files should be committed.
- Any optional manual apply/provisioning step is user-owned and can incur cloud cost.
- CI and scripts are intended for validation only.

## Current status

Bootstrap skeleton, validation guardrails, validation-only GitHub Actions CI, Terraform conventions, dev/prod Terraform environments, the shared network module, shared security-groups module, shared IAM module, shared load-balancer module, ECS/Fargate service module, private RDS PostgreSQL module, optional Redis cache module, CloudWatch observability module, metadata-only Secrets Manager reference module, public-safe service example catalog, and architecture diagrams are in place. Remaining detailed operating documentation will be added ticket-by-ticket.

## Quick start validation

Run the local quality gate:

```bash
bash scripts/quality-gate.sh
```

The quality gate checks shell syntax, repository structure, public-safety rules, forbidden Terraform state/plan/variable files, automated cloud mutation commands, Markdown link sanity, and Terraform formatting/validation when Terraform is installed. If Terraform is not installed locally, the Terraform check warns and skips; GitHub Actions installs Terraform and runs the same validation-only quality gate.

## Repository structure

```text
.
├── README.md
├── AGENTS.md
├── BUILD_TICKETS.md
├── BUILD_NOTES.md
├── .github/
│   └── workflows/
│       └── ci.yml
├── scripts/
│   ├── build-loop.sh
│   ├── check-doc-links.sh
│   ├── check-no-cloud-mutations.sh
│   ├── check-no-terraform-state.sh
│   ├── check-public-safety.sh
│   ├── check-terraform.sh
│   ├── self-test-guardrails.sh
│   └── quality-gate.sh
├── docs/
│   ├── architecture.md
│   ├── deployment.md
│   ├── rollback.md
│   ├── operations.md
│   ├── runbook.md
│   ├── cost-notes.md
│   ├── security.md
│   ├── secrets.md
│   ├── service-examples.md
│   ├── review-guide.md
│   ├── decisions/
│   └── diagrams/
│       └── aws-container-platform.md
└── infra/
    └── terraform/
        ├── modules/
        │   ├── ecs-service/
        │   ├── iam/
        │   ├── load-balancer/
        │   ├── network/
        │   ├── observability/
        │   ├── rds-postgres/
        │   ├── redis-cache/
        │   ├── secrets-manager-references/
        │   └── security-groups/
        └── environments/
            ├── dev/
            └── prod/
```

## Planned architecture themes

- VPC with public and private subnet intent implemented by the network module.
- Security group boundaries for public ALB ingress, private ECS services, private PostgreSQL/RDS, and optional private Redis/ElastiCache.
- IAM separation between the ECS task execution role and the application task role, with placeholder secret-reference read policies.
- Public Application Load Balancer with an HTTP listener, optional HTTPS variables, and listener-rule wiring to service target groups.
- ECS/Fargate service definitions and service-profile metadata for `carbon-platform-api`, `job-runner-platform`, and `multi-tenant-saas-api` using fake images, private subnet placement, log groups, target groups, health checks, listener rules, placeholder environment variables, secret references, database/cache dependency notes, and autoscaling settings.
- Private PostgreSQL/RDS instance pattern with private subnet group, no public accessibility, backups, deletion protection variables, storage sizing, log exports, and RDS-managed Secrets Manager master credentials.
- Optional private Redis/ElastiCache cache pattern with private subnet group, private security group input, enable/disable flag, encryption settings, snapshots, and replica/Multi-AZ production variables.
- CloudWatch observability module with an environment dashboard, ALB 5xx and unhealthy-target alarms, ECS CPU/memory alarms, RDS CPU/free-storage alarms, and ECS log-group naming conventions.
- Metadata-only AWS Secrets Manager reference containers for ECS secret injection, with no secret versions or values in Terraform.
- Secret references via AWS-native services rather than committed secret values.
- Separate dev/prod Terraform environments.

## Out of scope

- Running a real production workload from this repository.
- Storing application source code.
- Automatic cloud mutation from scripts or CI.
- Committing real account IDs, state, credentials, or private names.
