# BUILD_NOTES.md

## Current state

Tickets 000 through 009 are complete. The repository now has the public-safe skeleton, validation guardrails, Terraform conventions, dev/prod Terraform environment roots, shared AWS network module, shared security-groups module, shared IAM module, shared load-balancer module, ECS/Fargate service module wired for the three portfolio demo services, and a private RDS PostgreSQL module wired into both environments.

The next run should start with the lowest-numbered TODO ticket in `BUILD_TICKETS.md`.

## Quality gates

- `bash scripts/check-terraform.sh` — passed.
  - Ran `terraform fmt -recursive -check`, `terraform init -backend=false`, and `terraform validate` for both `dev` and `prod` using a temporary copy of the Terraform tree.
- `bash scripts/quality-gate.sh` — passed.
  - Guardrails for shell syntax, public safety, no Terraform state/plan/real tfvars files, no secret-like files, no cloud mutation automation, required Terraform module structure, and Terraform validation passed.

## Public-safety notes

This project is an independent public portfolio project.

Do not add employer code, private data, internal URLs, credentials, real cloud account IDs, screenshots, non-public architecture, or anything implying employer endorsement.

Do not commit Terraform state, real tfvars, plan files, cloud credentials, SSH keys, kubeconfig files, or `.env` files with secrets.

Do not add automated cloud mutation commands such as `terraform apply`, `terraform destroy`, `terraform import`, or cloud CLI deploy commands.

## Latest cycle notes

Changed in ticket 009:

- Added `infra/terraform/modules/rds-postgres/` with `main.tf`, `variables.tf`, `outputs.tf`, and `README.md`.
- Modeled a private RDS PostgreSQL instance pattern with:
  - private DB subnet group over environment private subnets
  - `publicly_accessible = false`
  - security group input supplied from the existing private RDS security group boundary
  - PostgreSQL engine/version, database name, instance class, port, storage, backup, deletion-protection, and final-snapshot variables
  - storage encryption enabled by default and optional user-owned KMS key references kept null in committed examples
  - RDS-managed master user password support through Secrets Manager, without accepting or committing a database password value
  - CloudWatch PostgreSQL log export variables, optional Enhanced Monitoring variables, and optional Performance Insights variables
  - review-friendly outputs for endpoint, resource ID, subnet group, backup summary, storage summary, monitoring summary, and credential-reference summary
- Wired the RDS PostgreSQL module into both `infra/terraform/environments/dev/` and `infra/terraform/environments/prod/`.
- Added environment variables and public-safe `terraform.tfvars.example` values for RDS sizing and safeguards:
  - dev uses a small single-AZ PostgreSQL shape, short backup retention, deletion protection disabled, and skipped final snapshot for disposable lab use
  - prod shows production intent with Multi-AZ, deletion protection, final snapshot, longer backup retention, retained automated backups, larger storage ceiling, and Performance Insights enabled
- Kept all committed examples public-safe:
  - no database password values
  - no real KMS key ARNs
  - no real secret ARNs for RDS credentials
  - no real account IDs beyond the allowed fake placeholder `123456789012` already used for demo secret-reference ARNs
- Updated Terraform module/environment documentation, README, architecture notes, security notes, deployment placeholder, operations placeholder, rollback placeholder, runbook placeholder, review guide placeholder, and cost notes for the private RDS PostgreSQL pattern.
- Updated `scripts/quality-gate.sh` to require the RDS module files and sanity-check RDS wiring in both environments.
- Marked ticket 009 as DONE in `BUILD_TICKETS.md`.

Limitations:

- The RDS module models a single `aws_db_instance` PostgreSQL pattern, not Aurora, RDS Proxy, read replicas, cross-region recovery, or custom parameter groups.
- RDS master credentials are managed by AWS Secrets Manager if a user manually provisions the lab; application connection-string secrets are still placeholder references and remain deferred to the dedicated secrets/reference ticket.
- Enhanced Monitoring is modeled but disabled in committed examples because a reviewed IAM monitoring role is not implemented yet.
- Performance Insights is enabled only in the prod example to show production intent; real use should review retention, cost, and regional support.
- The module exposes optional KMS key variables but committed examples keep them null because real KMS key ARNs must stay outside this public repo.
- Database migrations are documented at a high level in the module README only; detailed migration and rollback runbooks remain deferred to later documentation tickets.
- No Redis resource module or observability dashboard/alarm module is implemented yet; these remain deferred to later tickets.
- GitHub Actions CI is still deferred to ticket 014.

## Next recommended ticket

Ticket 010.
