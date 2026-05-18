# 0002 — Terraform modules and environments

## Status

Accepted.

## Context

The project needs to show infrastructure-as-code structure that is easy to review, validate, and discuss in interviews. It also needs clear environment separation between `dev` and `prod` while avoiding real backend configuration, real variable files, Terraform state, generated plans, credentials, or private account details.

A single flat Terraform root would be simple, but it would hide reusable boundaries and make it harder to demonstrate module interface design. A highly abstract module system would be harder to review and could distract from the architecture being demonstrated.

## Decision

Use explicit Terraform environment roots under `infra/terraform/environments/` and reusable modules under `infra/terraform/modules/`.

Each module has:

- `main.tf`
- `variables.tf`
- `outputs.tf`
- `README.md`

Each environment has:

- `providers.tf`
- `main.tf`
- `variables.tf`
- `outputs.tf`
- `backend.example.tf`
- `terraform.tfvars.example`
- `README.md`

The `dev` and `prod` roots use the same module set with different public-safe defaults and examples. Module interfaces prefer explicit variables, explicit outputs, and common tags. Real backend configuration is not committed; `backend.example.tf` documents shape only. Real values belong outside the repository. Validation uses backend-disabled initialisation.

## Consequences

This structure makes module boundaries, environment differences, and review intent visible. Reviewers can inspect the network, security-groups, load-balancer, ECS service, IAM, RDS, Redis, secrets-reference, and observability modules independently, then inspect how `dev` and `prod` compose them.

The trade-off is some intentional repetition between environments. That repetition is acceptable because it keeps the portfolio lab readable and avoids hiding important production-intent differences behind excessive abstraction.

Any future module change must keep the environment examples, module READMEs, outputs, and validation scripts in sync. The structure does not remove the need for production review of remote state, provider authentication, variable ownership, policy controls, and manual plan review if a user chooses to adapt the lab in a real account.
