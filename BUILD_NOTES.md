# BUILD_NOTES.md

## Current state

Tickets 000, 001, 002, 003, 004, and 005 are complete. The repository now has the public-safe skeleton, validation guardrails, Terraform conventions, dev/prod Terraform environment roots, the shared AWS network module, and a shared security-groups module wired into both environments.

The next run should start with the lowest-numbered TODO ticket in `BUILD_TICKETS.md`.

## Quality gates

- `bash scripts/quality-gate.sh` — passed.
  - `scripts/check-terraform.sh` ran `terraform fmt -recursive -check`, `terraform init -backend=false`, and `terraform validate` for both `dev` and `prod` using a temporary copy of the Terraform tree.
  - Guardrails for public safety, no Terraform state/plan/real tfvars files, no secret-like files, and no cloud mutation automation passed.

## Public-safety notes

This project is an independent public portfolio project.

Do not add employer code, private data, internal URLs, credentials, real cloud account IDs, screenshots, non-public architecture, or anything implying employer endorsement.

Do not commit Terraform state, real tfvars, plan files, cloud credentials, SSH keys, kubeconfig files, or `.env` files with secrets.

Do not add automated cloud mutation commands such as `terraform apply`, `terraform destroy`, `terraform import`, or cloud CLI deploy commands.

## Latest cycle notes

Changed in ticket 005:

- Added `infra/terraform/modules/security-groups/` with `main.tf`, `variables.tf`, `outputs.tf`, and `README.md`.
- Modeled security groups for the future public Application Load Balancer, private ECS services, private PostgreSQL/RDS, and optional private Redis/ElastiCache cache.
- Added explicit standalone ingress/egress rule resources for:
  - public IPv4 CIDRs to the ALB security group only on configured ALB edge ports
  - ALB security group to ECS service security group only on the service port
  - ECS service security group to PostgreSQL/RDS security group only on the database port
  - ECS service security group to Redis cache security group only when Redis is enabled
- Ensured database and cache security groups do not include public ingress rules.
- Wired the security-groups module into both `infra/terraform/environments/dev/` and `infra/terraform/environments/prod/`.
- Added environment variables, example values, and outputs for ALB ingress CIDRs/ports, service port, database port, Redis port, and security group IDs.
- Updated Terraform documentation, environment READMEs, top-level README, architecture notes, security notes, and cost notes to describe the implemented security group boundaries.
- Updated `scripts/quality-gate.sh` to require the security-groups module files and sanity-check security group wiring.
- Marked ticket 005 as DONE in `BUILD_TICKETS.md`.

Limitations:

- No IAM, load balancer, ECS service, RDS, Redis, or observability resources are implemented yet; these remain deferred to later tickets.
- The security group model uses one shared ECS service security group and one shared service port. Future service modules may need per-service security groups or ports if services have different exposure or data-store access patterns.
- The ECS egress model is intentionally strict and currently covers only database and optional cache access. Real workloads may need reviewed VPC endpoints, NAT egress, or narrow outbound rules for ECR image pulls, CloudWatch Logs, secret references, telemetry, AWS APIs, or third-party APIs.
- The ALB edge currently models HTTP ingress by default. Production use should review HTTPS-only ingress, certificate management, WAF, trusted CIDRs, IPv6, flow logs, and threat-detection requirements.
- GitHub Actions CI is still deferred to ticket 014.

## Next recommended ticket

Ticket 006.
