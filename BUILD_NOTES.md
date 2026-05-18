# BUILD_NOTES.md

## Current state

Tickets 000, 001, and 002 are complete. The repository now has the initial public-safe skeleton, reusable validation guardrails, and Terraform repository convention documentation for modules and environments.

The next run should start with the lowest-numbered TODO ticket in `BUILD_TICKETS.md`.

## Quality gates

- `bash scripts/quality-gate.sh` — passed.
  - Terraform was not installed locally, so `scripts/check-terraform.sh` warned and skipped local Terraform fmt/init/validate as designed. CI will install Terraform in a later ticket.

## Public-safety notes

This project is an independent public portfolio project.

Do not add employer code, private data, internal URLs, credentials, real cloud account IDs, screenshots, non-public architecture, or anything implying employer endorsement.

Do not commit Terraform state, real tfvars, plan files, cloud credentials, SSH keys, kubeconfig files, or `.env` files with secrets.

Do not add automated cloud mutation commands such as `terraform apply`, `terraform destroy`, `terraform import`, or cloud CLI deploy commands.

## Latest cycle notes

Changed in ticket 002:

- Added `infra/terraform/README.md` with repository-wide Terraform layout, naming, tagging, module, environment, backend, safety, and validation conventions.
- Added `infra/terraform/modules/README.md` with reusable module structure, interface, naming/tagging, security, cost, and validation expectations.
- Added `infra/terraform/environments/README.md` with environment root structure, dev/prod conventions, example variable file guidance, backend example policy, validation-only workflow, and manual apply policy.
- Updated `scripts/quality-gate.sh` to require the Terraform convention documentation and check for key safety/convention topics.
- Marked ticket 002 as DONE in `BUILD_TICKETS.md`.

Limitations:

- Terraform environment skeletons are not implemented yet; ticket 003 should add `dev` and `prod` roots.
- Terraform modules are not implemented yet; later tickets should add module code and per-module READMEs.
- Terraform is not installed in the local environment used for this cycle; the Terraform guardrail warns and skips locally by design.
- GitHub Actions CI is still deferred to ticket 014.

## Next recommended ticket

Ticket 003.
