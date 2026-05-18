# Prod Terraform environment

This root module is the public-safe `prod` environment for `platform-infra-lab`. It mirrors the dev structure while using production-intent defaults and examples for review.

## Current scope

The prod environment now wires `../../modules/network` with production-intent defaults:

- VPC CIDR: `10.30.0.0/16`
- three public subnets for future public edge resources such as an ALB
- three private subnets for future ECS services, database, and cache resources
- internet gateway and public route table
- one private route table per private subnet
- one shared NAT gateway enabled by default to demonstrate private egress

Future tickets add security groups, IAM, ECS service patterns, load balancing, RDS PostgreSQL, optional Redis, and observability.

## Prod posture

Prod demonstrates production intent rather than production completeness:

- three availability zones are shown for review of multi-AZ layout
- NAT gateway usage defaults to enabled to model private egress needs
- log retention defaults to a longer window than dev for future log groups
- deletion protection defaults to enabled for future stateful services
- Redis/cache usage defaults to enabled to show the optional private cache tier
- default ECS desired count is two tasks for future service examples

These settings can create ongoing cost if a user later provisions real infrastructure. Any real use must be reviewed, user-owned, and cleaned up by the operator.

## Network review notes

Public subnets are intended for internet-facing components only. Private subnets are intended for workloads and stateful services that should not receive public IP addresses. Security group rules are intentionally deferred to a later ticket so subnet placement and traffic boundaries can be reviewed separately.

The prod example uses a single shared NAT gateway to keep the pattern readable. A real production design should review per-availability-zone NAT gateways, VPC endpoints, flow logs, CIDR sizing, and regional availability-zone support before provisioning.

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
