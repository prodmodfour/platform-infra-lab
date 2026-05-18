# BUILD_NOTES.md

## Current state

Tickets 000 through 022 are complete. The repository now has the public-safe skeleton, validation guardrails, validation-only GitHub Actions CI, Terraform conventions, dev/prod Terraform environment roots, shared AWS network module, shared security-groups module, metadata-only Secrets Manager reference module, shared IAM module, shared load-balancer module, ECS/Fargate service module wired for the three portfolio demo services, private RDS PostgreSQL module, optional private Redis/Valkey-style cache module, CloudWatch observability module, public-safe service example catalog, architecture documentation with Mermaid/text diagrams, a validation-first deployment guide, rollback guide, operations guide, operational runbook, qualitative cost notes, security guide, hiring reviewer guide, and ADR documentation.

The next run should start with the lowest-numbered TODO ticket in `BUILD_TICKETS.md`.

## Quality gates

- `bash scripts/quality-gate.sh` — passed.
  - Ran bootstrap, README, CI workflow, Terraform convention, Terraform module, service example catalog, observability, security-group, architecture documentation, deployment documentation, rollback documentation, operations documentation, runbook documentation, cost documentation, security documentation, review guide documentation, ADR documentation, shell syntax, guardrail self-test, public-safety, no Terraform state/plan/real tfvars, no cloud mutation automation, Markdown link sanity, and Terraform validation checks.
  - Terraform validation ran `terraform fmt -recursive -check`, `terraform init -backend=false`, and `terraform validate` for both `dev` and `prod` using a temporary copy of the Terraform tree.

## Public-safety notes

This project is an independent public portfolio project.

Do not add employer code, private data, internal URLs, credentials, real cloud account IDs, screenshots, non-public architecture, or anything implying employer endorsement.

Do not commit Terraform state, real tfvars, plan files, cloud credentials, SSH keys, kubeconfig files, or `.env` files with secrets.

Do not add automated cloud mutation commands such as `terraform apply`, `terraform destroy`, `terraform import`, or cloud CLI deploy commands.

## Latest cycle notes

Changed in ticket 022:

- Added ADRs for ECS/Fargate as the container platform, Terraform modules and environments, private database/cache placement, secret references rather than values, and validation-only CI.
- Updated `scripts/quality-gate.sh` to require all five ADR files and validate the required `Status`, `Context`, `Decision`, and `Consequences` sections plus ticket-specific decision terms.
- Updated `README.md` current status to reflect that ADR documentation is now in place.
- Marked ticket 022 as DONE in `BUILD_TICKETS.md`.

Limitations:

- The ADRs document architecture decisions and trade-offs for the public portfolio lab; they do not make the lab production-ready or replace production-specific review.
- CI and local scripts remain validation-only and intentionally do not provision, modify, or destroy cloud resources.
- Final README polish is still deferred to ticket 023.

## Next recommended ticket

Ticket 023.
