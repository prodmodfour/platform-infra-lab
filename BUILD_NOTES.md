# BUILD_NOTES.md

## Current state

Tickets 000, 001, 002, and 003 are complete. The repository now has the initial public-safe skeleton, reusable validation guardrails, Terraform repository convention documentation, and validation-ready dev/prod Terraform environment roots.

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

Changed in ticket 003:

- Added `infra/terraform/environments/dev/` with `providers.tf`, `main.tf`, `variables.tf`, `outputs.tf`, `backend.example.tf`, `terraform.tfvars.example`, and `README.md`.
- Added `infra/terraform/environments/prod/` with the same root-module file structure and production-intent defaults/examples.
- Established public-safe environment locals for `name_prefix`, `common_tags`, network defaults, platform defaults, and the planned shared module contract.
- Added placeholder S3 backend examples that use fake bucket/table names and are intended only to show remote-state shape.
- Updated Terraform environment documentation, the Terraform root README, and the top-level README to mention the dev/prod skeletons.
- Updated `scripts/quality-gate.sh` to require and sanity-check the dev/prod environment skeleton files.
- Marked ticket 003 as DONE in `BUILD_TICKETS.md`.

Limitations:

- The dev/prod roots intentionally contain no AWS resources yet; resource modules are implemented in later tickets.
- Module calls are documented as the planned shared contract only; ticket 004 should add and wire the network module first.
- Terraform is not installed in the local environment used for this cycle; the Terraform guardrail warns and skips locally by design.
- GitHub Actions CI is still deferred to ticket 014.

## Next recommended ticket

Ticket 004.
