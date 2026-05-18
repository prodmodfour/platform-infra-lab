# BUILD_NOTES.md

## Current state

Tickets 000 through 007 are complete. The repository now has the public-safe skeleton, validation guardrails, Terraform conventions, dev/prod Terraform environment roots, shared AWS network module, shared security-groups module, shared IAM module, and an ECS/Fargate service module wired into both environments for the three portfolio demo services.

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

Changed in ticket 007:

- Added `infra/terraform/modules/ecs-service/` with `main.tf`, `variables.tf`, `outputs.tf`, and `README.md`.
- Modeled one private ECS/Fargate service per module instance with:
  - CloudWatch log group
  - task definition and single application container definition
  - ECS service using private subnets and supplied service security group IDs
  - ALB target group with `target_type = "ip"`
  - optional ALB listener rule wiring for later load-balancer integration
  - target-group and container health checks
  - deployment circuit breaker settings
  - desired-count autoscaling target plus CPU and memory target-tracking policies
- Kept service examples public-safe by constraining example images to fake `public.ecr.aws/example/...:demo` URIs.
- Modeled container secrets as Secrets Manager or SSM Parameter Store ARNs only; no secret values are accepted or committed.
- Added a shared ECS cluster to both `infra/terraform/environments/dev/` and `infra/terraform/environments/prod/`.
- Wired ECS service examples for:
  - `carbon-platform-api`
  - `job-runner-platform`
  - `multi-tenant-saas-api`
- Added dev defaults with one small task per service and small autoscaling ranges.
- Added prod defaults with two tasks per service and wider production-intent autoscaling ranges.
- Left ALB listener-rule creation disabled in both environments until the load-balancer module is added in ticket 008.
- Added ECS service outputs for cluster details, service summaries, target group ARNs, and log group names.
- Updated Terraform documentation, environment READMEs, architecture notes, security notes, deployment placeholder, operations placeholder, rollback placeholder, and cost notes to describe the ECS/Fargate service pattern.
- Updated `scripts/quality-gate.sh` to require the ECS service module files and sanity-check ECS service wiring in both environments.
- Marked ticket 007 as DONE in `BUILD_TICKETS.md`.

Limitations:

- The ECS service module creates target groups and ECS service load-balancer attachments, but the actual ALB/listener is deferred to ticket 008. Real manual provisioning should wait for that wiring or supply a reviewed listener ARN.
- IAM roles are still environment-level shared roles. Future hardening may use per-service task roles and tighter per-service secret ARN scopes.
- Placeholder secret-reference ARNs use fake account ID `123456789012` and demo paths. Real use must create and rotate secrets outside this repo or in secure user-owned pipelines.
- The current security-group egress model is intentionally narrow and does not yet model VPC endpoints or NAT egress required for real Fargate image pulls, CloudWatch logs, ECS APIs, or secret retrieval.
- The default container health check assumes the demo image has a compatible HTTP health endpoint and `curl`; real images should override the command if needed.
- No load balancer, RDS, Redis resource module, or observability dashboard/alarm module is implemented yet; these remain deferred to later tickets.
- GitHub Actions CI is still deferred to ticket 014.

## Next recommended ticket

Ticket 008.
