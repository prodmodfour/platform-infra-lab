# BUILD_NOTES.md

## Current state

Tickets 000 through 021 are complete. The repository now has the public-safe skeleton, validation guardrails, validation-only GitHub Actions CI, Terraform conventions, dev/prod Terraform environment roots, shared AWS network module, shared security-groups module, metadata-only Secrets Manager reference module, shared IAM module, shared load-balancer module, ECS/Fargate service module wired for the three portfolio demo services, private RDS PostgreSQL module, optional private Redis/Valkey-style cache module, CloudWatch observability module, public-safe service example catalog, architecture documentation with Mermaid/text diagrams, a validation-first deployment guide, rollback guide, operations guide, operational runbook, qualitative cost notes, security guide, and hiring reviewer guide.

The next run should start with the lowest-numbered TODO ticket in `BUILD_TICKETS.md`.

## Quality gates

- `bash scripts/quality-gate.sh` — passed.
  - Ran bootstrap, README, CI workflow, Terraform convention, Terraform module, service example catalog, observability, security-group, architecture documentation, deployment documentation, rollback documentation, operations documentation, runbook documentation, cost documentation, security documentation, review guide documentation, shell syntax, guardrail self-test, public-safety, no Terraform state/plan/real tfvars, no cloud mutation automation, Markdown link sanity, and Terraform validation checks.
  - Terraform validation ran `terraform fmt -recursive -check`, `terraform init -backend=false`, and `terraform validate` for both `dev` and `prod` using a temporary copy of the Terraform tree.

## Public-safety notes

This project is an independent public portfolio project.

Do not add employer code, private data, internal URLs, credentials, real cloud account IDs, screenshots, non-public architecture, or anything implying employer endorsement.

Do not commit Terraform state, real tfvars, plan files, cloud credentials, SSH keys, kubeconfig files, or `.env` files with secrets.

Do not add automated cloud mutation commands such as `terraform apply`, `terraform destroy`, `terraform import`, or cloud CLI deploy commands.

## Latest cycle notes

Changed in ticket 021:

- Replaced the placeholder `docs/review-guide.md` with a complete hiring reviewer guide covering a suggested 10-minute review path, suggested 30-minute review path, important modules to inspect, important docs to inspect, what the project demonstrates, what is intentionally out of scope, and how the lab complements the three backend service examples.
- Updated `scripts/quality-gate.sh` to require `docs/review-guide.md` and validate the ticket-required review guide sections.
- Updated `README.md` to reflect that the reviewer guide is now in place.
- Marked ticket 021 as DONE in `BUILD_TICKETS.md`.

Limitations:

- The review guide is a navigation aid for portfolio reviewers; it does not make the lab production-ready or replace the deeper architecture, security, deployment, rollback, operations, cost, and module documentation.
- ADR documentation is still deferred to ticket 022.
- CI and local scripts remain validation-only and intentionally do not provision, modify, or destroy cloud resources.

## Next recommended ticket

Ticket 022.
