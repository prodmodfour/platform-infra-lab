# Dev Terraform environment

This root module is the public-safe `dev` environment for `platform-infra-lab`. It establishes provider configuration, backend examples, variable defaults, outputs, naming, tagging, and the first concrete module: the shared network module.

## Current scope

The dev environment now wires `../../modules/network` with cost-aware defaults:

- VPC CIDR: `10.20.0.0/16`
- two public subnets for future public edge resources such as an ALB
- two private subnets for future ECS services, database, and cache resources
- internet gateway and public route table
- one private route table per private subnet
- NAT gateway disabled by default

Future tickets add security groups, IAM, ECS service patterns, load balancing, RDS PostgreSQL, optional Redis, and observability.

## Dev posture

Dev is intentionally small and cost-aware:

- two availability zones are shown for the platform pattern
- NAT gateway usage defaults to disabled until private egress is explicitly needed
- log retention defaults to a short demo-friendly window for future log groups
- deletion protection defaults to disabled for disposable lab experiments
- Redis/cache usage defaults to disabled
- default ECS desired count is one task for future service examples

These are placeholders for review and validation, not a production recommendation.

## Network review notes

Public subnets are intended for internet-facing components only. Private subnets are intended for workloads and stateful services that should not receive public IP addresses. Security group rules are intentionally deferred to a later ticket so subnet placement and traffic boundaries can be reviewed separately.

If NAT is enabled for a real dev experiment, it can create ongoing cloud cost. Keep it disabled unless the workload needs private outbound internet access, and clean up user-owned resources after review.

## Public-safety notes

- `backend.example.tf` uses fake placeholder bucket and lock-table names.
- `terraform.tfvars.example` contains only placeholder values.
- Do not commit real `.tfvars`, Terraform state, generated plans, credentials, SSH keys, kubeconfigs, or `.env` files.
- Any future manual provisioning is optional, user-owned, and can incur cloud cost. This repository does not automate provisioning.

## Validation

From the repository root, run:

```bash
bash scripts/quality-gate.sh
```

When Terraform is installed, the guardrail validates this environment with backend access disabled so no cloud account is required for validation.
