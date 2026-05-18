# BUILD_NOTES.md

## Current state

Tickets 000 through 012 are complete. The repository now has the public-safe skeleton, validation guardrails, Terraform conventions, dev/prod Terraform environment roots, shared AWS network module, shared security-groups module, metadata-only Secrets Manager reference module, shared IAM module, shared load-balancer module, ECS/Fargate service module wired for the three portfolio demo services, private RDS PostgreSQL module, optional private Redis/Valkey-style cache module, and CloudWatch observability module wired into both environments.

The next run should start with the lowest-numbered TODO ticket in `BUILD_TICKETS.md`.

## Quality gates

- `bash scripts/check-terraform.sh` — passed.
  - Ran `terraform fmt -recursive -check`, `terraform init -backend=false`, and `terraform validate` for both `dev` and `prod` using a temporary copy of the Terraform tree.
- `bash scripts/quality-gate.sh` — passed.
  - Guardrails for shell syntax, public safety, no Terraform state/plan/real tfvars files, no secret-like files, no cloud mutation automation, required Terraform module structure, Secrets Manager reference module wiring, observability module wiring, and Terraform validation passed.

## Public-safety notes

This project is an independent public portfolio project.

Do not add employer code, private data, internal URLs, credentials, real cloud account IDs, screenshots, non-public architecture, or anything implying employer endorsement.

Do not commit Terraform state, real tfvars, plan files, cloud credentials, SSH keys, kubeconfig files, or `.env` files with secrets.

Do not add automated cloud mutation commands such as `terraform apply`, `terraform destroy`, `terraform import`, or cloud CLI deploy commands.

## Latest cycle notes

Changed in ticket 012:

- Added `infra/terraform/modules/secrets-manager-references/` with `main.tf`, `variables.tf`, `outputs.tf`, and `README.md`.
- Modeled an AWS Secrets Manager reference pattern that creates metadata-only `aws_secretsmanager_secret` containers for ECS task-definition secret injection.
- Intentionally did not add `aws_secretsmanager_secret_version`, generated passwords, secret strings, real secret values, real account IDs, or secret-writing automation.
- Wired the secrets reference module into both `infra/terraform/environments/dev/` and `infra/terraform/environments/prod/`.
- Added per-environment `ecs_secret_definitions`, `secrets_manager_kms_key_id`, and `secrets_manager_recovery_window_in_days` inputs with public-safe placeholder metadata only.
- Updated ECS service wiring so module-generated Secrets Manager ARNs feed `secret_references`, while per-service extra references remain empty in committed examples.
- Updated IAM wiring so the ECS task execution role receives module-created Secrets Manager ARNs plus optional empty extra scopes; direct application task-role secret reads remain opt-in.
- Added environment outputs for Secrets Manager reference defaults, names, ARNs, metadata summary, and value-management summary.
- Added `docs/secrets.md` and updated architecture, deployment, rollback, operations, runbook, cost, security, review, Terraform convention, module, environment, and root README documentation for the secret-reference pattern.
- Updated `scripts/quality-gate.sh` to require the new module/docs, verify environment wiring, and reject `aws_secretsmanager_secret_version` resources in Terraform.
- Marked ticket 012 as DONE in `BUILD_TICKETS.md`.

Limitations:

- The module creates secret metadata containers only; real secret values must be created outside this public repo or by a secure user-owned pipeline before any real service can use them.
- Rotation schedules, rotation Lambdas, emergency rotation procedures, and application reload behavior are documented as user-owned production work.
- The current pattern covers ECS task-definition secret injection; direct application SDK reads remain opt-in through explicit additional task-role ARNs.
- Customer-managed KMS key usage is modeled as optional input only; real key policies, grants, and matching `kms:Decrypt` scopes must be reviewed by the operator.
- Secrets Manager resources can create cost if manually provisioned; exact prices are not claimed because costs change.
- GitHub Actions CI is still deferred to ticket 014.

## Next recommended ticket

Ticket 013.
