# BUILD_NOTES.md

## Current state

Tickets 000 through 017 are complete. The repository now has the public-safe skeleton, validation guardrails, validation-only GitHub Actions CI, Terraform conventions, dev/prod Terraform environment roots, shared AWS network module, shared security-groups module, metadata-only Secrets Manager reference module, shared IAM module, shared load-balancer module, ECS/Fargate service module wired for the three portfolio demo services, private RDS PostgreSQL module, optional private Redis/Valkey-style cache module, CloudWatch observability module, public-safe service example catalog, architecture documentation with Mermaid/text diagrams, a validation-first deployment guide, and a rollback guide.

The next run should start with the lowest-numbered TODO ticket in `BUILD_TICKETS.md`.

## Quality gates

- `bash scripts/quality-gate.sh` — passed.
  - Ran bootstrap, README, CI workflow, Terraform convention, Terraform module, service example catalog, observability, security-group, architecture documentation, deployment documentation, rollback documentation, shell syntax, guardrail self-test, public-safety, no Terraform state/plan/real tfvars, no cloud mutation automation, Markdown link sanity, and Terraform validation checks.
  - Terraform validation ran `terraform fmt -recursive -check`, `terraform init -backend=false`, and `terraform validate` for both `dev` and `prod` using a temporary copy of the Terraform tree.

## Public-safety notes

This project is an independent public portfolio project.

Do not add employer code, private data, internal URLs, credentials, real cloud account IDs, screenshots, non-public architecture, or anything implying employer endorsement.

Do not commit Terraform state, real tfvars, plan files, cloud credentials, SSH keys, kubeconfig files, or `.env` files with secrets.

Do not add automated cloud mutation commands such as `terraform apply`, `terraform destroy`, `terraform import`, or cloud CLI deploy commands.

## Latest cycle notes

Changed in ticket 017:

- Replaced the placeholder `docs/rollback.md` with a full rollback guide covering the required strategies: bad container image, failing health checks, failed ECS deployment, bad environment variable or secret reference, database migration issue, RDS incident, Redis/cache issue, and ALB/routing issue.
- Added a rollback decision tree, component-specific symptoms, rollback strategies, verification steps, metrics/logs to check, communication notes, and safety notes.
- Kept the rollback posture documentation-only and validation-first: no rollback scripts, no CI deployment, no CI rollback, no automated cloud mutation, and no real secrets or private values.
- Updated `docs/deployment.md` so failed post-deploy checks point to the new rollback guide.
- Updated `README.md` to note that the rollback guide is now in place.
- Updated `scripts/quality-gate.sh` to require `docs/rollback.md` and check for the key rollback guide sections.
- Marked ticket 017 as DONE in `BUILD_TICKETS.md`.

Limitations:

- The rollback guide is operational documentation only; it does not add rollback automation, provisioning scripts, or CI cloud mutation.
- Any real rollback remains optional, manual, user-owned, and may require AWS credentials, real images, real secret values, private values, and component-specific procedures outside this public repo.
- The guide intentionally avoids storing real incident data, private account details, database dumps, generated plans, Terraform state, or secret values.
- Detailed operations guide, runbook, cost notes, security guide, review guide, and ADR documentation is still deferred to later tickets.

## Next recommended ticket

Ticket 018.
