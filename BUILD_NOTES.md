# BUILD_NOTES.md

## Current state

Tickets 000 through 008 are complete. The repository now has the public-safe skeleton, validation guardrails, Terraform conventions, dev/prod Terraform environment roots, shared AWS network module, shared security-groups module, shared IAM module, shared load-balancer module, and ECS/Fargate service module wired into both environments for the three portfolio demo services.

The next run should start with the lowest-numbered TODO ticket in `BUILD_TICKETS.md`.

## Quality gates

- `bash scripts/check-terraform.sh` — passed.
  - Ran `terraform fmt -recursive -check`, `terraform init -backend=false`, and `terraform validate` for both `dev` and `prod` using a temporary copy of the Terraform tree.
- `bash scripts/quality-gate.sh` — passed.
  - Guardrails for shell syntax, public safety, no Terraform state/plan/real tfvars files, no secret-like files, no cloud mutation automation, and Terraform validation passed.

## Public-safety notes

This project is an independent public portfolio project.

Do not add employer code, private data, internal URLs, credentials, real cloud account IDs, screenshots, non-public architecture, or anything implying employer endorsement.

Do not commit Terraform state, real tfvars, plan files, cloud credentials, SSH keys, kubeconfig files, or `.env` files with secrets.

Do not add automated cloud mutation commands such as `terraform apply`, `terraform destroy`, `terraform import`, or cloud CLI deploy commands.

## Latest cycle notes

Changed in ticket 008:

- Added `infra/terraform/modules/load-balancer/` with `main.tf`, `variables.tf`, `outputs.tf`, and `README.md`.
- Modeled the public ALB edge with:
  - internet-facing Application Load Balancer by default
  - required HTTP listener with a fixed-response default action for unmatched routes
  - optional HTTPS listener variables that require a user-owned ACM certificate ARN when enabled
  - optional ALB access-log configuration that references an existing user-owned S3 bucket when enabled
  - outputs for ALB DNS, zone ID, listener ARNs, listener summaries, and target-group wiring pattern
- Wired the load-balancer module into both `infra/terraform/environments/dev/` and `infra/terraform/environments/prod/`.
- Passed `module.load_balancer.http_listener_arn` into the ECS service module by default so each demo service now creates path-based listener rules for its target group.
- Kept all committed examples public-safe:
  - no real certificate ARN
  - no real access-log bucket
  - no real DNS name or hosted zone
  - fake service images only
  - placeholder secret-reference ARNs only
- Updated environment defaults and examples for ALB HTTP, optional HTTPS, access logs, deletion protection, and listener-rule creation.
- Added load-balancer outputs to both environments.
- Updated Terraform module/environment documentation, README, architecture notes, security notes, deployment placeholder, operations placeholder, rollback placeholder, and cost notes for the ALB public-edge pattern.
- Updated `scripts/quality-gate.sh` to require the load-balancer module files and sanity-check load-balancer wiring in both environments.
- Marked ticket 008 as DONE in `BUILD_TICKETS.md`.

Limitations:

- HTTPS is modeled but disabled in committed examples because real ACM certificate ARNs and domain details must stay outside this public repo.
- ALB access logs are modeled but disabled in committed examples because a real user-owned S3 log bucket and bucket policy are outside this repo.
- The ALB listener default action is a fixed response; service reachability depends on the ECS service listener rules and path patterns.
- Prod enables ALB deletion protection to show production intent, but real cleanup requires explicitly reviewing and disabling it before user-owned destruction.
- IAM roles are still environment-level shared roles. Future hardening may use per-service task roles and tighter per-service secret ARN scopes.
- Placeholder secret-reference ARNs use fake account ID `123456789012` and demo paths. Real use must create and rotate secrets outside this repo or in secure user-owned pipelines.
- The current security-group egress model is intentionally narrow and does not yet model VPC endpoints or NAT egress required for real Fargate image pulls, CloudWatch logs, ECS APIs, or secret retrieval.
- The default container health check assumes the demo image has a compatible HTTP health endpoint and `curl`; real images should override the command if needed.
- No RDS, Redis resource module, or observability dashboard/alarm module is implemented yet; these remain deferred to later tickets.
- GitHub Actions CI is still deferred to ticket 014.

## Next recommended ticket

Ticket 009.
