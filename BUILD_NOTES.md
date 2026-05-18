# BUILD_NOTES.md

## Current state

Tickets 000 through 023 are complete. The repository now has the public-safe skeleton, validation guardrails, validation-only GitHub Actions CI, Terraform conventions, dev/prod Terraform environment roots, shared AWS network module, shared security-groups module, metadata-only Secrets Manager reference module, shared IAM module, shared load-balancer module, ECS/Fargate service module wired for the three portfolio demo services, private RDS PostgreSQL module, optional private Redis/Valkey-style cache module, CloudWatch observability module, public-safe service example catalog, architecture documentation with Mermaid/text diagrams, a validation-first deployment guide, rollback guide, operations guide, operational runbook, qualitative cost notes, security guide, hiring reviewer guide, ADR documentation, and polished top-level README.

The next run should start with the lowest-numbered TODO ticket in `BUILD_TICKETS.md`.

## Quality gates

- `bash scripts/quality-gate.sh` — passed.
  - Ran bootstrap, README framing/final-polish, CI workflow, Terraform convention, Terraform module, service example catalog, observability, security-group, architecture documentation, deployment documentation, rollback documentation, operations documentation, runbook documentation, cost documentation, security documentation, review guide documentation, ADR documentation, shell syntax, guardrail self-test, public-safety, no Terraform state/plan/real tfvars, no cloud mutation automation, Markdown link sanity, and Terraform validation checks.
  - Terraform validation ran `terraform fmt -recursive -check`, `terraform init -backend=false`, and `terraform validate` for both `dev` and `prod` using a temporary copy of the Terraform tree.

## Public-safety notes

This project is an independent public portfolio project.

Do not add employer code, private data, internal URLs, credentials, real cloud account IDs, screenshots, non-public architecture, or anything implying employer endorsement.

Do not commit Terraform state, real tfvars, plan files, cloud credentials, SSH keys, kubeconfig files, or `.env` files with secrets.

Do not add automated cloud mutation commands such as `terraform apply`, `terraform destroy`, `terraform import`, or cloud CLI deploy commands.

## Latest cycle notes

Changed in ticket 023:

- Reworked `README.md` so the first screen clearly states the portfolio value and the document includes the required safety, scope, requirements, validation, architecture, module, environment, CI, docs-link, review-path, and limitations sections.
- Updated `scripts/quality-gate.sh` with README final-polish checks for required headings, architecture terms, and key documentation/module/environment links.
- Marked ticket 023 as DONE in `BUILD_TICKETS.md`.

Limitations:

- The README is a portfolio and review guide; it does not make the lab production-ready or replace account-specific production design.
- CI and local scripts remain validation-only and intentionally do not provision, modify, or destroy cloud resources.
- Final autonomous review and completion marker are still deferred to ticket 024.

## Next recommended ticket

Ticket 024.
