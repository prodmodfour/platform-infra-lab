# BUILD_NOTES.md

## Current state

Tickets 000 through 020 are complete. The repository now has the public-safe skeleton, validation guardrails, validation-only GitHub Actions CI, Terraform conventions, dev/prod Terraform environment roots, shared AWS network module, shared security-groups module, metadata-only Secrets Manager reference module, shared IAM module, shared load-balancer module, ECS/Fargate service module wired for the three portfolio demo services, private RDS PostgreSQL module, optional private Redis/Valkey-style cache module, CloudWatch observability module, public-safe service example catalog, architecture documentation with Mermaid/text diagrams, a validation-first deployment guide, rollback guide, operations guide, operational runbook, qualitative cost notes, and a security guide.

The next run should start with the lowest-numbered TODO ticket in `BUILD_TICKETS.md`.

## Quality gates

- `bash scripts/quality-gate.sh` — passed.
  - Ran bootstrap, README, CI workflow, Terraform convention, Terraform module, service example catalog, observability, security-group, architecture documentation, deployment documentation, rollback documentation, operations documentation, runbook documentation, cost documentation, security documentation, shell syntax, guardrail self-test, public-safety, no Terraform state/plan/real tfvars, no cloud mutation automation, Markdown link sanity, and Terraform validation checks.
  - Terraform validation ran `terraform fmt -recursive -check`, `terraform init -backend=false`, and `terraform validate` for both `dev` and `prod` using a temporary copy of the Terraform tree.

## Public-safety notes

This project is an independent public portfolio project.

Do not add employer code, private data, internal URLs, credentials, real cloud account IDs, screenshots, non-public architecture, or anything implying employer endorsement.

Do not commit Terraform state, real tfvars, plan files, cloud credentials, SSH keys, kubeconfig files, or `.env` files with secrets.

Do not add automated cloud mutation commands such as `terraform apply`, `terraform destroy`, `terraform import`, or cloud CLI deploy commands.

## Latest cycle notes

Changed in ticket 020:

- Replaced the placeholder `docs/security.md` with a complete security guide covering no committed secrets, no Terraform state in git, IAM role separation, least-privilege intent, private database/cache boundaries, public ALB boundary, the secret reference pattern, validation-only CI posture, manual apply warnings, production hardening gaps, an access review checklist, and a threat model summary.
- Updated `scripts/quality-gate.sh` to require `docs/security.md` and validate the ticket-required security guide sections.
- Updated `README.md` to reflect that the security guide is now in place.
- Marked ticket 020 as DONE in `BUILD_TICKETS.md`.

Limitations:

- The security guide documents the modeled posture and review expectations; it does not make the lab production-ready by itself.
- Production-specific controls such as TLS/DNS/WAF, private egress strategy, image provenance, KMS policy review, secret rotation automation, database restore testing, Redis AUTH/ACL decisions, and incident routing remain user-owned outside this public repo.
- CI and local scripts remain validation-only and intentionally do not provision, modify, or destroy cloud resources.
- Review guide and ADR documentation are still deferred to later tickets.

## Next recommended ticket

Ticket 021.
