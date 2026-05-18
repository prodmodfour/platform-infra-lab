# BUILD_NOTES.md

## Current state

Tickets 000, 001, 002, 003, and 004 are complete. The repository now has the public-safe skeleton, validation guardrails, Terraform conventions, dev/prod Terraform environment roots, and a shared AWS network module wired into both environments.

The next run should start with the lowest-numbered TODO ticket in `BUILD_TICKETS.md`.

## Quality gates

- `bash scripts/quality-gate.sh` — passed.
  - Terraform was installed locally for this cycle.
  - `scripts/check-terraform.sh` ran `terraform fmt -recursive -check`, `terraform init -backend=false`, and `terraform validate` for both `dev` and `prod` using a temporary copy of the Terraform tree.

## Public-safety notes

This project is an independent public portfolio project.

Do not add employer code, private data, internal URLs, credentials, real cloud account IDs, screenshots, non-public architecture, or anything implying employer endorsement.

Do not commit Terraform state, real tfvars, plan files, cloud credentials, SSH keys, kubeconfig files, or `.env` files with secrets.

Do not add automated cloud mutation commands such as `terraform apply`, `terraform destroy`, `terraform import`, or cloud CLI deploy commands.

## Latest cycle notes

Changed in ticket 004:

- Added `infra/terraform/modules/network/` with `main.tf`, `variables.tf`, `outputs.tf`, and `README.md`.
- Modeled a VPC, public subnets, private subnets, an internet gateway, public/private route tables, public internet routing, optional single NAT gateway, and NAT-backed private egress routes when enabled.
- Added public-safe module inputs for naming, environment, VPC/subnet CIDRs, availability zones, NAT enablement, DNS behavior, and common tags.
- Added outputs for VPC ID/CIDR, public/private subnet IDs and CIDRs, route table IDs, internet gateway ID, NAT enablement, and NAT gateway ID.
- Wired the network module into both `infra/terraform/environments/dev/` and `infra/terraform/environments/prod/`.
- Updated dev/prod outputs and README files to describe the implemented network resources and NAT posture.
- Updated Terraform documentation, top-level README, architecture placeholder, cost notes, and security notes to reflect the implemented network module.
- Updated `scripts/quality-gate.sh` to require the network module files and sanity-check network module wiring.
- Marked ticket 004 as DONE in `BUILD_TICKETS.md`.

Limitations:

- Security groups are intentionally not implemented yet; ticket 005 should add load balancer, service, database, and cache traffic boundaries.
- The network module uses one optional shared NAT gateway when enabled. Production use should review per-availability-zone NAT gateways, VPC endpoints, flow logs, IPv6, CIDR sizing, and account-specific availability-zone support.
- No load balancer, ECS, RDS, Redis, IAM, or observability resources exist yet; they remain deferred to later tickets.
- GitHub Actions CI is still deferred to ticket 014.

## Next recommended ticket

Ticket 005.
