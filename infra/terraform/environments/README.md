# Terraform environment conventions

This directory contains Terraform root modules for deployable environments. Environment directories are added in later tickets, starting with `dev` and `prod`.

Environment roots are responsible for composing reusable modules with environment-specific inputs. They are the main review surface for proposed infrastructure changes.

## Required environment structure

Each environment must include:

```text
<environment>/
├── providers.tf
├── main.tf
├── variables.tf
├── outputs.tf
├── backend.example.tf
├── terraform.tfvars.example
└── README.md
```

Do not commit real `.tfvars` files, real backend configuration, generated plan files, Terraform state, local credentials, or local `.env` files.

## Environment responsibilities

Each environment root should:

- pin or constrain Terraform and provider versions in `providers.tf`
- define public-safe local naming and `common_tags`
- call the same core modules as other environments unless a documented exception exists
- pass dependency outputs explicitly between modules
- keep environment-specific sizing, retention, and feature flags visible in variables or examples
- expose only useful outputs, such as load balancer DNS names, service names, dashboard names, or database endpoint references
- document review notes, expected cost posture, and production hardening gaps in its `README.md`

## Dev and prod conventions

`dev` should demonstrate the platform pattern with lower-cost defaults where practical. Examples include smaller desired counts, shorter log retention, optional NAT gateway usage, smaller database/cache sizing, and relaxed deletion protection where safe for a lab.

`prod` should demonstrate production intent rather than guarantee production readiness. Examples include higher availability settings, stronger log retention, deletion protection for stateful services, tighter scaling thresholds, and clear notes about remaining hardening work.

Both environments must remain public-safe and should use generic demo services only.

## Variable files

Commit only `terraform.tfvars.example` with placeholder values. Examples should show the shape of required inputs without exposing real values.

Allowed example values include:

- fake image names such as `public.ecr.aws/example/carbon-platform-api:demo`
- placeholder regions such as `us-east-1`
- generic CIDR ranges intended only for the lab
- placeholder secret reference names or ARNs clearly marked as examples

Do not commit:

- real `.tfvars` files
- credentials or tokens
- real account IDs
- private hosted zone names or internal URLs
- real backend bucket or lock table names
- generated plan files

## Backend examples

Each environment should include `backend.example.tf` to document the intended remote-state pattern. This file must contain placeholder values only.

Real backend details are user-owned and must stay outside committed files. Validation must use backend-disabled initialisation so the repository can be reviewed and checked without cloud account access.

```bash
terraform init -backend=false
```

## Validation-only workflow

Local and CI workflows should run validation only:

- shell syntax checks
- public-safety guardrails
- Terraform state and generated-plan guardrails
- no cloud mutation automation checks
- `terraform fmt -recursive -check`
- `terraform init -backend=false`
- `terraform validate`

No script or CI workflow should provision, destroy, import, or otherwise mutate cloud resources.

## Manual apply policy

Any apply step is optional, manual, user-owned, and can incur cloud cost. It should happen only after the operator has reviewed the plan, confirmed backend configuration, confirmed secrets are managed outside this repository, and accepted the cost and cleanup responsibility.

This repository's portfolio value should not depend on applying infrastructure.
