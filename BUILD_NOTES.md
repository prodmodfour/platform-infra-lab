# BUILD_NOTES.md

## Current state

Tickets 000 through 016 are complete. The repository now has the public-safe skeleton, validation guardrails, validation-only GitHub Actions CI, Terraform conventions, dev/prod Terraform environment roots, shared AWS network module, shared security-groups module, metadata-only Secrets Manager reference module, shared IAM module, shared load-balancer module, ECS/Fargate service module wired for the three portfolio demo services, private RDS PostgreSQL module, optional private Redis/Valkey-style cache module, CloudWatch observability module, public-safe service example catalog, architecture documentation with Mermaid/text diagrams, and a validation-first deployment guide.

The next run should start with the lowest-numbered TODO ticket in `BUILD_TICKETS.md`.

## Quality gates

- `bash scripts/quality-gate.sh` — passed.
  - Ran bootstrap, README, CI workflow, Terraform convention, Terraform module, service example catalog, observability, security-group, architecture documentation, deployment documentation, shell syntax, guardrail self-test, public-safety, no Terraform state/plan/real tfvars, no cloud mutation automation, Markdown link sanity, and Terraform validation checks.
  - Terraform validation ran `terraform fmt -recursive -check`, `terraform init -backend=false`, and `terraform validate` for both `dev` and `prod` using a temporary copy of the Terraform tree.

## Public-safety notes

This project is an independent public portfolio project.

Do not add employer code, private data, internal URLs, credentials, real cloud account IDs, screenshots, non-public architecture, or anything implying employer endorsement.

Do not commit Terraform state, real tfvars, plan files, cloud credentials, SSH keys, kubeconfig files, or `.env` files with secrets.

Do not add automated cloud mutation commands such as `terraform apply`, `terraform destroy`, `terraform import`, or cloud CLI deploy commands.

## Latest cycle notes

Changed in ticket 016:

- Replaced the placeholder `docs/deployment.md` with a full validation-first deployment guide covering pre-deploy review, required local tools, local validation, backend-disabled Terraform initialisation, user-owned backend initialisation, plan review, manual apply warnings, service image update flow, environment promotion, migration considerations, and post-deploy checks.
- Emphasised that any provisioning is optional, manual, user-owned, and can incur cost; scripts and CI remain validation-only.
- Documented how to keep real backend settings, variable files, secret values, image references, generated plans, and credentials outside the public repository.
- Updated `README.md` to mention that the deployment guide is now in place.
- Updated `scripts/quality-gate.sh` to require `docs/deployment.md` and check for the key deployment guide sections.
- Marked ticket 016 as DONE in `BUILD_TICKETS.md`.

Limitations:

- The deployment guide is operational documentation only; it does not add provisioning scripts or CI cloud mutation.
- Terraform plan/apply examples are manual user-owned commands and may require AWS credentials, real images, and real secret values outside this repo.
- The committed service images remain fake placeholders and are not intended to run production workloads.
- Detailed rollback, operations, cost, security, review, and ADR documentation is still deferred to later tickets.

## Next recommended ticket

Ticket 017.
