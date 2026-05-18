# Security

This project must not commit secrets, Terraform state, generated plans, cloud credentials, SSH keys, kubeconfigs, private data, or real account IDs.

Current local guardrails are validation-only and run through `bash scripts/quality-gate.sh`:

- `scripts/check-public-safety.sh` scans for local environment files, private key files/material, AWS credential-looking files/content, and non-placeholder 12-digit account IDs.
- `scripts/check-no-terraform-state.sh` rejects Terraform state, generated plan files, real `.tfvars` files, and local `.env` files.
- `scripts/check-no-cloud-mutations.sh` scans scripts and CI-style automation files for Terraform/cloud mutation commands.
- `scripts/check-terraform.sh` runs Terraform formatting and environment validation when Terraform is installed; otherwise it warns locally.

## Current infrastructure security posture

The network module separates public and private subnet intent:

- public subnets are for future internet-facing edge resources such as an ALB
- private subnets are for future ECS services, databases, and caches
- private subnets do not map public IP addresses on launch
- database/cache security group rules are not implemented yet and are intentionally deferred to the security-group ticket

Future content will document IAM role separation, least-privilege intent, private database/cache access, public ALB boundaries, secret references, validation-only CI, and production hardening gaps.
