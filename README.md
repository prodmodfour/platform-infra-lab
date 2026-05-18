# platform-infra-lab — public-safe AWS ECS/Fargate platform lab

`platform-infra-lab` is an independent public portfolio project that demonstrates backend/platform/SRE infrastructure work with reviewable AWS/Terraform code, validation-only CI, and operations documentation.

It models how containerised backend services can run behind an Application Load Balancer on ECS/Fargate with private PostgreSQL/RDS, optional private Redis/ElastiCache, IAM role boundaries, secret references, CloudWatch observability, deployment guidance, rollback notes, and cost/security guardrails.

## Portfolio framing

This repository is designed for hiring reviewers who want evidence of platform engineering judgment without needing access to a real cloud account. The value is in the Terraform structure, module interfaces, environment separation, security boundaries, runbooks, and validation guardrails.

Reference service profiles are placeholders only:

- `carbon-platform-api`
- `job-runner-platform`
- `multi-tenant-saas-api`

No application source code is included here.

## Public-safety constraints

This repo is intentionally safe to publish:

- Independent public portfolio project; no employer code, private architecture, internal hostnames, private data, or endorsement implication.
- Public-safe placeholder names and fake image references only.
- No committed secrets, credentials, SSH keys, kubeconfigs, private keys, or `.env` secret files.
- No Terraform state, generated plan files, or real `.tfvars` files.
- No real cloud account IDs or private resource names.

## Cloud-safety constraints

This project is validation-first and does not automatically mutate cloud infrastructure:

- No automatic cloud deployment from scripts or CI.
- CI and local scripts run validation only.
- Any optional manual apply can incur cloud cost and is user-owned.
- Backend configuration is example-only via `backend.example.tf`; no real backend bucket/table is committed.
- Environment values are examples only via `terraform.tfvars.example`; real values must stay outside git.

## Implemented scope

The current implementation includes:

- Terraform repository conventions and validation guardrails.
- Dev and prod Terraform environment roots.
- Shared modules for network, security groups, IAM, load balancing, ECS/Fargate services, RDS PostgreSQL, optional Redis cache, Secrets Manager references, and observability.
- Public-safe service examples for the three placeholder backend services.
- CloudWatch dashboard/alarm patterns and ECS log group conventions.
- GitHub Actions validation CI.
- Architecture, deployment, rollback, operations, runbook, cost, security, review, service example, secrets, and ADR documentation.

## Out of scope

This repository intentionally does not include:

- Real application code or another web application implementation.
- Production-ready guarantees or account-specific hardening.
- Automatic provisioning, deployment, rollback, import, or destruction automation.
- Real secrets, real account IDs, real Terraform backend configuration, state files, or generated plans.
- Exact current cloud price estimates.

## Requirements

For local review:

- `bash`
- `git`
- `python3` for Markdown link sanity checks
- Terraform CLI, optional locally but required for full Terraform validation; GitHub Actions installs Terraform for CI

AWS credentials are not required to run the quality gate because Terraform validation uses backend access disabled.

## Quick start validation

Run the local quality gate from the repository root:

```bash
bash scripts/quality-gate.sh
```

The quality gate checks repository structure, shell syntax, public-safety rules, forbidden state/plan/secret-like files, cloud-mutation automation guardrails, Markdown links, Terraform formatting, and Terraform environment validation when Terraform is available.

## Repository structure

```text
.
├── README.md
├── AGENTS.md
├── BUILD_TICKETS.md
├── BUILD_NOTES.md
├── .github/workflows/ci.yml
├── scripts/
│   ├── build-loop.sh
│   ├── check-doc-links.sh
│   ├── check-no-cloud-mutations.sh
│   ├── check-no-terraform-state.sh
│   ├── check-public-safety.sh
│   ├── check-terraform.sh
│   ├── quality-gate.sh
│   └── self-test-guardrails.sh
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
│   └── diagrams/aws-container-platform.md
└── infra/terraform/
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

## Architecture summary

The modeled platform flow is:

1. Public clients reach an internet-facing Application Load Balancer in public subnets.
2. ALB listener rules route service paths to ECS/Fargate target groups.
3. ECS services run in private subnets with no public task IPs.
4. ECS tasks use separate execution and application task roles.
5. PostgreSQL/RDS runs in private subnets and accepts traffic only from ECS service security groups.
6. Redis/ElastiCache is optional and private, with dev disabled by default and prod enabled as a production-intent example.
7. Secret values are not stored in Terraform; ECS receives AWS Secrets Manager references.
8. CloudWatch logs, metrics, dashboards, and alarms provide the observability pattern.

See [docs/architecture.md](docs/architecture.md) and [docs/diagrams/aws-container-platform.md](docs/diagrams/aws-container-platform.md).

## Terraform module summary

| Module | Purpose |
| --- | --- |
| [`network`](infra/terraform/modules/network/README.md) | VPC, public/private subnets, route table intent, internet gateway, optional NAT gateway. |
| [`security-groups`](infra/terraform/modules/security-groups/README.md) | Public ALB boundary, private ECS ingress, private RDS/Redis rules. |
| [`iam`](infra/terraform/modules/iam/README.md) | ECS task execution role, application task role, and scoped secret-reference read policies. |
| [`load-balancer`](infra/terraform/modules/load-balancer/README.md) | Application Load Balancer, HTTP listener, optional HTTPS/listener patterns, access-log placeholders. |
| [`ecs-service`](infra/terraform/modules/ecs-service/README.md) | Task definition, service, target group, listener rule, health checks, log group, autoscaling. |
| [`rds-postgres`](infra/terraform/modules/rds-postgres/README.md) | Private PostgreSQL/RDS instance, subnet group, backups, deletion protection, managed password reference. |
| [`redis-cache`](infra/terraform/modules/redis-cache/README.md) | Optional private Redis/Valkey-style cache, subnet group, replicas/failover/encryption variables. |
| [`secrets-manager-references`](infra/terraform/modules/secrets-manager-references/README.md) | Metadata-only Secrets Manager containers for ECS secret references; no secret values. |
| [`observability`](infra/terraform/modules/observability/README.md) | CloudWatch dashboard, ALB/ECS/RDS alarms, and log group naming outputs. |

## Environment summary

| Environment | Intent | Notable defaults |
| --- | --- | --- |
| [`dev`](infra/terraform/environments/dev/README.md) | Small, cost-aware review environment. | Two AZ layout, NAT disabled, Redis disabled, one ECS task per service, short retention, deletion protection disabled for disposable experiments. |
| [`prod`](infra/terraform/environments/prod/README.md) | Production-intent example for review. | Three AZ layout, NAT enabled, Redis enabled, two ECS tasks per service, Multi-AZ/failover examples, deletion protection and longer retention where practical. |

Both environments use public-safe `terraform.tfvars.example` files and example-only `backend.example.tf` files.

## CI and quality gate summary

GitHub Actions runs [`.github/workflows/ci.yml`](.github/workflows/ci.yml), which installs Terraform and executes:

```bash
bash scripts/quality-gate.sh
```

The workflow is validation-only. It checks shell syntax, public-safety guardrails, Terraform fmt/init/validate, Markdown links, no Terraform state/plan/real tfvars, and no automated cloud mutation commands.

## Deployment and rollback docs

- [Deployment guide](docs/deployment.md): validation, manual initialization, plan review, optional user-owned provisioning warnings, image update flow, migration notes, and post-deploy checks.
- [Rollback guide](docs/rollback.md): bad image, failing health checks, failed ECS deployment, secret/config issues, database migration issues, RDS incidents, Redis issues, and ALB/routing issues.
- [Operations guide](docs/operations.md) and [runbook](docs/runbook.md): health checks, logs, metrics, alarms, triage, database/cache issues, stuck deployments, cost cleanup, and access review.

## Cost and security docs

- [Cost notes](docs/cost-notes.md): qualitative cost drivers, NAT/RDS/ALB/ECS/CloudWatch/Redis implications, dev/prod trade-offs, cleanup checklist, and accidental-spend avoidance.
- [Security guide](docs/security.md): no committed secrets/state, IAM role separation, least-privilege intent, private data tiers, public ALB boundary, secret reference pattern, CI posture, hardening gaps, and access review.
- [Secrets guide](docs/secrets.md): values stay outside this public repo; Terraform models references only.
- [ADRs](docs/decisions/): accepted architecture decisions and trade-offs.

## Suggested review path

For a 10-minute review:

1. Start with this README.
2. Scan [docs/architecture.md](docs/architecture.md) and the diagram.
3. Inspect [`infra/terraform/environments/dev/main.tf`](infra/terraform/environments/dev/main.tf).
4. Inspect [`infra/terraform/modules/ecs-service/README.md`](infra/terraform/modules/ecs-service/README.md) and [`infra/terraform/modules/security-groups/README.md`](infra/terraform/modules/security-groups/README.md).
5. Run `bash scripts/quality-gate.sh` if reviewing locally.

For a deeper review, follow [docs/review-guide.md](docs/review-guide.md).

## Limitations

- This is a portfolio lab, not a complete production platform.
- HTTPS, WAF, VPC endpoints, centralized audit logging, paging integrations, image signing, policy-as-code, drift detection, and account-specific controls require additional user-owned design.
- Terraform examples are reviewable and validatable, but real provisioning would require user-owned backend configuration, variables, AWS credentials, and cost controls outside this repo.
- Database migrations and application release automation are documented as operational considerations but are not implemented here.
