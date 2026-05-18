# BUILD_NOTES.md

## Current state

Tickets 000 through 018 are complete. The repository now has the public-safe skeleton, validation guardrails, validation-only GitHub Actions CI, Terraform conventions, dev/prod Terraform environment roots, shared AWS network module, shared security-groups module, metadata-only Secrets Manager reference module, shared IAM module, shared load-balancer module, ECS/Fargate service module wired for the three portfolio demo services, private RDS PostgreSQL module, optional private Redis/Valkey-style cache module, CloudWatch observability module, public-safe service example catalog, architecture documentation with Mermaid/text diagrams, a validation-first deployment guide, rollback guide, operations guide, and operational runbook.

The next run should start with the lowest-numbered TODO ticket in `BUILD_TICKETS.md`.

## Quality gates

- `bash scripts/quality-gate.sh` — passed.
  - Ran bootstrap, README, CI workflow, Terraform convention, Terraform module, service example catalog, observability, security-group, architecture documentation, deployment documentation, rollback documentation, operations documentation, runbook documentation, shell syntax, guardrail self-test, public-safety, no Terraform state/plan/real tfvars, no cloud mutation automation, Markdown link sanity, and Terraform validation checks.
  - Terraform validation ran `terraform fmt -recursive -check`, `terraform init -backend=false`, and `terraform validate` for both `dev` and `prod` using a temporary copy of the Terraform tree.

## Public-safety notes

This project is an independent public portfolio project.

Do not add employer code, private data, internal URLs, credentials, real cloud account IDs, screenshots, non-public architecture, or anything implying employer endorsement.

Do not commit Terraform state, real tfvars, plan files, cloud credentials, SSH keys, kubeconfig files, or `.env` files with secrets.

Do not add automated cloud mutation commands such as `terraform apply`, `terraform destroy`, `terraform import`, or cloud CLI deploy commands.

## Latest cycle notes

Changed in ticket 018:

- Replaced the placeholder `docs/operations.md` with a full operations guide covering platform operating model, health checks, logs, metrics, alarms, incident triage, RDS connectivity issues, service crash loops, high 5xx rate, high latency, database saturation, Redis unavailability, stuck deployments, cost cleanup, access review, and production hardening gaps.
- Replaced the placeholder `docs/runbook.md` with step-by-step public-safe incident playbooks for universal triage, health checks, logs, metrics, alarms, RDS connectivity, service crash loops, high 5xx rate, high latency, database saturation, Redis unavailable, deployment stuck, cost cleanup, access review, and closeout.
- Updated `scripts/quality-gate.sh` to require the operations/runbook files and check for the key ticket-required sections.
- Updated `README.md` and `docs/README.md` to reflect that the operations guide and operational runbook are now in place.
- Marked ticket 018 as DONE in `BUILD_TICKETS.md`.

Limitations:

- The operations guide and runbook are documentation only; they do not add deployment, rollback, cleanup, access-management, or incident-response automation.
- Any real operations remain optional, manual, user-owned, and may require AWS credentials, real images, real secret values, private values, and environment-specific procedures outside this public repo.
- Alarm action lists remain intentionally empty in committed Terraform examples; real paging or incident routing must be supplied through user-owned configuration outside this repository.
- Detailed cost notes, security guide, review guide, and ADR documentation are still deferred to later tickets.

## Next recommended ticket

Ticket 019.
