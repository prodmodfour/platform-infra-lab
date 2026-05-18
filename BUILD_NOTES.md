# BUILD_NOTES.md

## Current state

Tickets 000 and 001 are complete. The repository now has the initial public-safe skeleton plus reusable validation guardrails for public-safety, forbidden Terraform/local secret files, no automated cloud mutations, and Terraform formatting/validation when Terraform is installed.

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

Changed in ticket 001:

- Added `scripts/check-public-safety.sh` to scan the working tree for unsafe local env files, private key files/material, AWS credential-looking files/content, and non-placeholder 12-digit account IDs.
- Added `scripts/check-no-terraform-state.sh` to reject Terraform state, generated plan files, real `.tfvars` files, and local `.env` files.
- Added `scripts/check-no-cloud-mutations.sh` to scan scripts and CI-style automation files for Terraform/cloud mutation commands while allowing documentation-only warnings.
- Added `scripts/check-terraform.sh` to run `terraform fmt -recursive -check`, `terraform init -backend=false`, and `terraform validate` for Terraform environments when Terraform is available.
- Added `scripts/self-test-guardrails.sh` with temporary-fixture self-checks for the guardrails.
- Updated `scripts/quality-gate.sh` to run the new guardrails and self-tests.
- Updated `README.md` and `docs/security.md` with the current validation/security guardrail behavior.

Limitations:

- Terraform modules and environments are not implemented yet, so Terraform init/validate has no environments to validate.
- Terraform is not installed in the local environment used for this cycle; the Terraform guardrail warns and skips locally by design.
- GitHub Actions CI is still deferred to ticket 014.

## Next recommended ticket

Ticket 002.
