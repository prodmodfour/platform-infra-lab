# BUILD_NOTES.md

## Current state

Tickets 000 through 014 are complete. The repository now has the public-safe skeleton, validation guardrails, validation-only GitHub Actions CI, Terraform conventions, dev/prod Terraform environment roots, shared AWS network module, shared security-groups module, metadata-only Secrets Manager reference module, shared IAM module, shared load-balancer module, ECS/Fargate service module wired for the three portfolio demo services, private RDS PostgreSQL module, optional private Redis/Valkey-style cache module, CloudWatch observability module, and a public-safe service example catalog for the three portfolio apps.

The next run should start with the lowest-numbered TODO ticket in `BUILD_TICKETS.md`.

## Quality gates

- `bash scripts/quality-gate.sh` — passed.
  - Ran bootstrap, documentation, Terraform module, service example catalog, CI workflow, shell syntax, guardrail self-test, public-safety, no Terraform state/plan/real tfvars, no cloud mutation automation, Markdown link sanity, and Terraform validation checks.
  - Terraform validation ran `terraform fmt -recursive -check`, `terraform init -backend=false`, and `terraform validate` for both `dev` and `prod` using a temporary copy of the Terraform tree.

## Public-safety notes

This project is an independent public portfolio project.

Do not add employer code, private data, internal URLs, credentials, real cloud account IDs, screenshots, non-public architecture, or anything implying employer endorsement.

Do not commit Terraform state, real tfvars, plan files, cloud credentials, SSH keys, kubeconfig files, or `.env` files with secrets.

Do not add automated cloud mutation commands such as `terraform apply`, `terraform destroy`, `terraform import`, or cloud CLI deploy commands.

## Latest cycle notes

Changed in ticket 014:

- Added `.github/workflows/ci.yml` with a validation-only GitHub Actions workflow for pull requests, pushes to `main`, and manual dispatch.
- The CI workflow checks out the repository, installs Terraform, and runs `bash scripts/quality-gate.sh`; it does not configure cloud credentials or run cloud mutation commands.
- Added `scripts/check-doc-links.sh` for deterministic local Markdown link sanity checks without fetching external URLs.
- Updated `scripts/quality-gate.sh` to require the CI workflow, verify key CI wiring, and run Markdown link sanity checks.
- Updated README and Terraform documentation to describe validation-only CI and the Markdown link check.
- Marked ticket 014 as DONE in `BUILD_TICKETS.md`.

Limitations:

- CI is validation-only and intentionally does not plan, apply, destroy, import, or deploy cloud resources.
- The Markdown link check validates local repository links and headings; it intentionally does not fetch external URLs.
- Terraform validation still relies on public provider downloads during CI and does not prove that a real user-owned AWS account can apply the configuration.
- Detailed architecture diagrams and operating documentation are still deferred to later tickets.

## Next recommended ticket

Ticket 015.
