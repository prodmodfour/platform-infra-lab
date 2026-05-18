# BUILD_NOTES.md

## Current state

Tickets 000 through 010 are complete. The repository now has the public-safe skeleton, validation guardrails, Terraform conventions, dev/prod Terraform environment roots, shared AWS network module, shared security-groups module, shared IAM module, shared load-balancer module, ECS/Fargate service module wired for the three portfolio demo services, private RDS PostgreSQL module, and optional private Redis/Valkey-style cache module wired into both environments.

The next run should start with the lowest-numbered TODO ticket in `BUILD_TICKETS.md`.

## Quality gates

- `bash scripts/check-terraform.sh` — passed.
  - Ran `terraform fmt -recursive -check`, `terraform init -backend=false`, and `terraform validate` for both `dev` and `prod` using a temporary copy of the Terraform tree.
- `bash scripts/quality-gate.sh` — passed.
  - Guardrails for shell syntax, public safety, no Terraform state/plan/real tfvars files, no secret-like files, no cloud mutation automation, required Terraform module structure, Redis module wiring, and Terraform validation passed.

## Public-safety notes

This project is an independent public portfolio project.

Do not add employer code, private data, internal URLs, credentials, real cloud account IDs, screenshots, non-public architecture, or anything implying employer endorsement.

Do not commit Terraform state, real tfvars, plan files, cloud credentials, SSH keys, kubeconfig files, or `.env` files with secrets.

Do not add automated cloud mutation commands such as `terraform apply`, `terraform destroy`, `terraform import`, or cloud CLI deploy commands.

## Latest cycle notes

Changed in ticket 010:

- Added `infra/terraform/modules/redis-cache/` with `main.tf`, `variables.tf`, `outputs.tf`, and `README.md`.
- Modeled an optional private ElastiCache Redis/Valkey-style cache pattern with:
  - private ElastiCache subnet group over environment private subnets
  - cluster-mode-disabled `aws_elasticache_replication_group`
  - `enabled` flag so disabled environments create no cache resources
  - private Redis security group input supplied from the existing security-groups module
  - engine, engine version, node type, port, parameter group, replica count, automatic failover, Multi-AZ, encryption, snapshot, maintenance-window, and apply-timing variables
  - at-rest and in-transit encryption enabled by default
  - no Redis AUTH token, ACL secret, or connection-string secret value stored in Terraform
  - review-friendly outputs for enabled state, subnet group, replication group, private endpoints, availability summary, security summary, snapshot summary, and connection-reference summary
- Wired the Redis cache module into both `infra/terraform/environments/dev/` and `infra/terraform/environments/prod/`.
- Added environment variables and public-safe `terraform.tfvars.example` values for Redis sizing and safeguards:
  - dev keeps `enable_redis = false`, zero replicas, no snapshots, and a small optional node shape for disposable experiments
  - prod keeps `enable_redis = true`, one replica, automatic failover, Multi-AZ, encryption, snapshot retention, and a public-safe final snapshot identifier to show production intent
- Kept all committed examples public-safe:
  - no Redis AUTH token values
  - no real KMS key ARNs
  - no real cache endpoint hostnames
  - no real account IDs beyond the allowed fake placeholder `123456789012` already used for demo secret-reference ARNs
- Updated Terraform module/environment documentation, README, architecture notes, security notes, deployment placeholder, operations placeholder, rollback placeholder, runbook placeholder, review guide placeholder, and cost notes for the optional private Redis cache pattern.
- Updated `scripts/quality-gate.sh` to require the Redis module files and sanity-check Redis wiring in both environments.
- Marked ticket 010 as DONE in `BUILD_TICKETS.md`.

Limitations:

- The Redis cache module models a simple cluster-mode-disabled replication group, not a sharded cluster-mode topology.
- The module does not manage Redis AUTH tokens, ACL user groups, or application connection-string secrets; those remain deferred to the dedicated secrets/reference ticket and should be handled through a secure secret workflow.
- Dev keeps Redis disabled by default for cost awareness; endpoint outputs are null unless a user-owned manual experiment enables it.
- Prod enables a small cache example to demonstrate private cache and failover intent, but real production use should review node sizing, replicas, parameter groups, TLS client compatibility, eviction policy, backup/restore operations, global datastore needs, and cost.
- Redis log delivery, CloudWatch alarms, dashboards, and cache incident runbooks remain deferred to later observability and operations tickets.
- GitHub Actions CI is still deferred to ticket 014.

## Next recommended ticket

Ticket 011.
