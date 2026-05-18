# BUILD_NOTES.md

## Current state

Tickets 000 through 019 are complete. The repository now has the public-safe skeleton, validation guardrails, validation-only GitHub Actions CI, Terraform conventions, dev/prod Terraform environment roots, shared AWS network module, shared security-groups module, metadata-only Secrets Manager reference module, shared IAM module, shared load-balancer module, ECS/Fargate service module wired for the three portfolio demo services, private RDS PostgreSQL module, optional private Redis/Valkey-style cache module, CloudWatch observability module, public-safe service example catalog, architecture documentation with Mermaid/text diagrams, a validation-first deployment guide, rollback guide, operations guide, operational runbook, and qualitative cost notes.

The next run should start with the lowest-numbered TODO ticket in `BUILD_TICKETS.md`.

## Quality gates

- `bash scripts/quality-gate.sh` — passed.
  - Ran bootstrap, README, CI workflow, Terraform convention, Terraform module, service example catalog, observability, security-group, architecture documentation, deployment documentation, rollback documentation, operations documentation, runbook documentation, cost documentation, shell syntax, guardrail self-test, public-safety, no Terraform state/plan/real tfvars, no cloud mutation automation, Markdown link sanity, and Terraform validation checks.
  - Terraform validation ran `terraform fmt -recursive -check`, `terraform init -backend=false`, and `terraform validate` for both `dev` and `prod` using a temporary copy of the Terraform tree.

## Public-safety notes

This project is an independent public portfolio project.

Do not add employer code, private data, internal URLs, credentials, real cloud account IDs, screenshots, non-public architecture, or anything implying employer endorsement.

Do not commit Terraform state, real tfvars, plan files, cloud credentials, SSH keys, kubeconfig files, or `.env` files with secrets.

Do not add automated cloud mutation commands such as `terraform apply`, `terraform destroy`, `terraform import`, or cloud CLI deploy commands.

## Latest cycle notes

Changed in ticket 019:

- Replaced the placeholder `docs/cost-notes.md` with qualitative cost-awareness documentation covering cost drivers, NAT gateway implications, RDS implications, ALB implications, ECS Fargate drivers, CloudWatch log/metric costs, Redis/ElastiCache costs, dev versus prod trade-offs, cleanup checklist, and accidental-spend avoidance.
- Documented that the cost guide does not claim exact current AWS prices and that any optional manual provisioning is user-owned and can incur cost.
- Updated `scripts/quality-gate.sh` to require `docs/cost-notes.md` and check the key ticket-required cost sections.
- Updated `README.md` to reflect that qualitative cost notes are now in place.
- Marked ticket 019 as DONE in `BUILD_TICKETS.md`.

Limitations:

- The cost notes are documentation only; they do not add budgets, cleanup automation, provisioning automation, or cost-enforcement policies.
- The cost notes intentionally avoid exact AWS prices because prices vary by region, date, discounts, and usage pattern.
- Any real cost estimation, provisioning, cleanup, budgets, alerts, or account-level controls remain optional, manual, and user-owned outside this public repo.
- Security guide, review guide, and ADR documentation are still deferred to later tickets.

## Next recommended ticket

Ticket 020.
