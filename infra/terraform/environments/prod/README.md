# Prod Terraform environment

This root module is the public-safe `prod` skeleton for `platform-infra-lab`. It mirrors the dev environment structure while using production-intent defaults and examples for review.

## Scope in this ticket

This environment currently contains no AWS resources. It validates the root-module structure only:

- AWS provider version constraints and default tags
- public-safe naming via `name_prefix`
- prod network CIDR placeholders
- higher-availability defaults for future ECS, logs, database, and cache modules
- a placeholder S3 backend example that is not real backend configuration

Future tickets wire the same planned module set into both `dev` and `prod`: network, security groups, IAM, ECS service, load balancer, RDS PostgreSQL, optional Redis, and observability.

## Prod posture

Prod demonstrates production intent rather than production completeness:

- three availability zones are shown for review of multi-AZ layout
- NAT gateway usage defaults to enabled to model private egress needs
- log retention defaults to a longer window than dev
- deletion protection defaults to enabled for future stateful services
- Redis/cache usage defaults to enabled to show the optional private cache tier
- default ECS desired count is two tasks for future service examples

These settings can create ongoing cost if a user later provisions real infrastructure. Any real use must be reviewed, user-owned, and cleaned up by the operator.

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
