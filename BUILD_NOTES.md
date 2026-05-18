# BUILD_NOTES.md

## Current state

Tickets 000 through 015 are complete. The repository now has the public-safe skeleton, validation guardrails, validation-only GitHub Actions CI, Terraform conventions, dev/prod Terraform environment roots, shared AWS network module, shared security-groups module, metadata-only Secrets Manager reference module, shared IAM module, shared load-balancer module, ECS/Fargate service module wired for the three portfolio demo services, private RDS PostgreSQL module, optional private Redis/Valkey-style cache module, CloudWatch observability module, public-safe service example catalog, and architecture documentation with Mermaid/text diagrams.

The next run should start with the lowest-numbered TODO ticket in `BUILD_TICKETS.md`.

## Quality gates

- `bash scripts/quality-gate.sh` — passed.
  - Ran bootstrap, README, CI workflow, Terraform convention, Terraform module, service example catalog, observability, security-group, architecture documentation, shell syntax, guardrail self-test, public-safety, no Terraform state/plan/real tfvars, no cloud mutation automation, Markdown link sanity, and Terraform validation checks.
  - Terraform validation ran `terraform fmt -recursive -check`, `terraform init -backend=false`, and `terraform validate` for both `dev` and `prod` using a temporary copy of the Terraform tree.

## Public-safety notes

This project is an independent public portfolio project.

Do not add employer code, private data, internal URLs, credentials, real cloud account IDs, screenshots, non-public architecture, or anything implying employer endorsement.

Do not commit Terraform state, real tfvars, plan files, cloud credentials, SSH keys, kubeconfig files, or `.env` files with secrets.

Do not add automated cloud mutation commands such as `terraform apply`, `terraform destroy`, `terraform import`, or cloud CLI deploy commands.

## Latest cycle notes

Changed in ticket 015:

- Replaced the placeholder `docs/architecture.md` with a detailed public-safe architecture guide covering VPC/subnet layout, ALB public edge, private ECS service placement, private RDS PostgreSQL, optional private Redis/Valkey cache, CloudWatch logs/metrics, IAM roles, secret references, environment separation, request flow, deployment flow, module responsibilities, and production hardening gaps.
- Added `docs/diagrams/aws-container-platform.md` with Mermaid/text diagrams for the high-level platform, network layout, security group boundaries, request flow, deployment flow, environment separation, and observability coverage.
- Updated `docs/README.md` and `README.md` to reference the new architecture diagram status.
- Updated `scripts/quality-gate.sh` to require the architecture diagram and check for key architecture documentation sections.
- Marked ticket 015 as DONE in `BUILD_TICKETS.md`.

Limitations:

- The diagrams are public-safe logical diagrams, not screenshots or account-specific topology exports.
- CI remains validation-only and intentionally does not plan, apply, destroy, import, or deploy cloud resources.
- Terraform validation does not prove that a real user-owned AWS account can provision the design; it verifies formatting and static configuration validity.
- Detailed deployment, rollback, operations, cost, security, review, and ADR documentation is still deferred to later tickets.

## Next recommended ticket

Ticket 016.
