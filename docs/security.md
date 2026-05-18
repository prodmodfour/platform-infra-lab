# Security

This project must not commit secrets, Terraform state, generated plans, cloud credentials, SSH keys, kubeconfigs, private data, or real account IDs.

Current local guardrails are validation-only and run through `bash scripts/quality-gate.sh`:

- `scripts/check-public-safety.sh` scans for local environment files, private key files/material, AWS credential-looking files/content, and non-placeholder 12-digit account IDs.
- `scripts/check-no-terraform-state.sh` rejects Terraform state, generated plan files, real `.tfvars` files, and local `.env` files.
- `scripts/check-no-cloud-mutations.sh` scans scripts and CI-style automation files for Terraform/cloud mutation commands.
- `scripts/check-terraform.sh` runs Terraform formatting and environment validation when Terraform is installed; otherwise it warns locally.

Future content will document IAM role separation, least-privilege intent, private database/cache access, public ALB boundaries, secret references, validation-only CI, and production hardening gaps.
