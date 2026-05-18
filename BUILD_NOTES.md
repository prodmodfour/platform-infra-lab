# BUILD_NOTES.md

## Current state

Tickets 000 through 006 are complete. The repository now has the public-safe skeleton, validation guardrails, Terraform conventions, dev/prod Terraform environment roots, the shared AWS network module, the shared security-groups module, and the shared IAM module wired into both environments.

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

Changed in ticket 006:

- Added `infra/terraform/modules/iam/` with `main.tf`, `variables.tf`, `outputs.tf`, and `README.md`.
- Modeled an ECS task execution role trusted by `ecs-tasks.amazonaws.com` and attached the AWS-managed `AmazonECSTaskExecutionRolePolicy` for ECS runtime needs.
- Modeled a separate application ECS task role so future workloads do not inherit execution-role permissions.
- Added optional inline policies for approved Secrets Manager, SSM Parameter Store, and KMS reference ARNs on both the execution role and task role.
- Kept secret handling reference-only: the module accepts ARNs, rejects full wildcard resources, and does not accept or output secret values.
- Wired the IAM module into both `infra/terraform/environments/dev/` and `infra/terraform/environments/prod/` using fake account ID `123456789012` and public-safe placeholder secret-reference paths.
- Added environment variables, example values, and outputs for ECS task execution role ARNs, task role ARNs, and secret-reference policy summaries.
- Updated Terraform documentation, environment READMEs, top-level README, architecture notes, security notes, and cost notes to describe IAM role separation and reference-only secret access.
- Updated `scripts/quality-gate.sh` to require the IAM module files and sanity-check IAM wiring.
- Marked ticket 006 as DONE in `BUILD_TICKETS.md`.

Limitations:

- IAM roles are currently environment-level shared roles. Future ECS service work may introduce per-service task roles for tighter least-privilege boundaries.
- Placeholder secret-reference ARNs use path wildcards for readability. Real production use should replace them with exact ARNs where practical and review all grants with IAM Access Analyzer.
- The IAM module only models secret-reference read permissions plus the standard ECS execution managed policy. Application-specific AWS API permissions remain intentionally absent until a future service need is documented.
- Customer-managed KMS decrypt access is optional and empty by default; real use must align IAM permissions with KMS key policies and rotation ownership.
- No load balancer, ECS service, RDS, Redis, or observability resources are implemented yet; these remain deferred to later tickets.
- GitHub Actions CI is still deferred to ticket 014.

## Next recommended ticket

Ticket 007.
