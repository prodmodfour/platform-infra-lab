# Dev Terraform environment

This root module is the public-safe `dev` skeleton for `platform-infra-lab`. It establishes provider configuration, backend examples, variable defaults, outputs, naming, and tagging conventions before resource modules are added in later tickets.

## Scope in this ticket

This environment currently contains no AWS resources. It validates the root-module structure only:

- AWS provider version constraints and default tags
- public-safe naming via `name_prefix`
- dev network CIDR placeholders
- cost-aware defaults for future ECS, logs, database, and cache modules
- a placeholder S3 backend example that is not real backend configuration

Future tickets wire the same planned module set into both `dev` and `prod`: network, security groups, IAM, ECS service, load balancer, RDS PostgreSQL, optional Redis, and observability.

## Dev posture

Dev is intentionally small and cost-aware:

- two availability zones are shown for the platform pattern
- NAT gateway usage defaults to disabled until explicitly needed
- log retention defaults to a short demo-friendly window
- deletion protection defaults to disabled for disposable lab experiments
- Redis/cache usage defaults to disabled
- default ECS desired count is one task for future service examples

These are placeholders for review and validation, not a recommendation for production.

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
