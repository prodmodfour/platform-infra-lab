# BUILD_NOTES.md

## Current state

Tickets 000 through 013 are complete. The repository now has the public-safe skeleton, validation guardrails, Terraform conventions, dev/prod Terraform environment roots, shared AWS network module, shared security-groups module, metadata-only Secrets Manager reference module, shared IAM module, shared load-balancer module, ECS/Fargate service module wired for the three portfolio demo services, private RDS PostgreSQL module, optional private Redis/Valkey-style cache module, CloudWatch observability module, and a public-safe service example catalog for the three portfolio apps.

The next run should start with the lowest-numbered TODO ticket in `BUILD_TICKETS.md`.

## Quality gates

- `bash scripts/quality-gate.sh` — passed.
  - Ran bootstrap, documentation, Terraform module, service example catalog, shell syntax, guardrail self-test, public-safety, no Terraform state/plan/real tfvars, no cloud mutation automation, and Terraform validation checks.
  - Terraform validation ran `terraform fmt -recursive -check`, `terraform init -backend=false`, and `terraform validate` for both `dev` and `prod` using a temporary copy of the Terraform tree.

## Public-safety notes

This project is an independent public portfolio project.

Do not add employer code, private data, internal URLs, credentials, real cloud account IDs, screenshots, non-public architecture, or anything implying employer endorsement.

Do not commit Terraform state, real tfvars, plan files, cloud credentials, SSH keys, kubeconfig files, or `.env` files with secrets.

Do not add automated cloud mutation commands such as `terraform apply`, `terraform destroy`, `terraform import`, or cloud CLI deploy commands.

## Latest cycle notes

Changed in ticket 013:

- Added `docs/service-examples.md` with public-safe documentation for `carbon-platform-api`, `job-runner-platform`, and `multi-tenant-saas-api`.
- Documented each service's fake image, listener paths, expected health path, placeholder environment variables, database/cache needs, secret references, metrics/logging expectations, and deployment notes.
- Added `service_example_profiles` variables to both `infra/terraform/environments/dev/` and `infra/terraform/environments/prod/`.
- Added `service_example_catalog` locals and outputs in both environments so reviewers can inspect service-example metadata from Terraform output without exposing secret values.
- Updated `terraform.tfvars.example` in both environments with public-safe service profile metadata only.
- Updated root, docs, Terraform, architecture, deployment, and environment documentation to reference the service example catalog.
- Updated `scripts/quality-gate.sh` to require `docs/service-examples.md` and validate the service example catalog/profile wiring.
- Marked ticket 013 as DONE in `BUILD_TICKETS.md`.

Limitations:

- Service examples still use fake `public.ecr.aws/example/...:demo` images and include no application code.
- Secret references remain metadata-only; real secret values must be created outside this public repo or by a secure user-owned pipeline before any real service could run.
- The service profile catalog is review/documentation metadata; it does not verify real application behavior.
- Dev keeps Redis disabled by default for cost-aware review, so Redis-dependent real job or SaaS behavior would require an explicit user-owned change.
- GitHub Actions CI is still deferred to ticket 014.

## Next recommended ticket

Ticket 014.
