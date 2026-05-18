# Secret reference pattern

This project models secret handling with AWS Secrets Manager references, not committed values.

## What Terraform models

`infra/terraform/modules/secrets-manager-references` creates Secrets Manager metadata-only secret containers for ECS task-definition secret injection:

- `DATABASE_URL` for services that need PostgreSQL connection details
- `JOB_RUNNER_API_KEY` for the job-runner example
- `JWT_SIGNING_KEY` for the multi-tenant API example

The module creates `aws_secretsmanager_secret` resources only. It does not create `aws_secretsmanager_secret_version`, does not accept secret strings, and does not generate passwords in Terraform.

## Where secret values live

Secret values must be created outside this public repository or by a secure user-owned pipeline. This repo intentionally does not include commands, scripts, CI jobs, `.tfvars`, or examples that write secret values.

Committed examples contain only metadata such as public-safe names and descriptions. Real account IDs, private secret paths, and secret values do not belong in git.

## How applications receive secrets

Environment roots pass the module outputs into the ECS service module:

```hcl
secret_references = merge(
  each.value.secret_references,
  lookup(module.secrets_manager_references.ecs_secret_references_by_service, each.key, {})
)
```

The ECS task definition receives Secrets Manager ARNs in its container `secrets` block. ECS resolves those references at runtime through the task execution role and injects the values into container environment variables. The application sees the runtime value; Terraform and this repository store only the ARN reference.

## IAM boundary

The IAM module grants the ECS task execution role read access to the Secrets Manager ARNs emitted by the secrets reference module. The application task role stays separate and does not need direct secret-read permission for ECS-injected secrets.

If a real application reads secrets directly with the AWS SDK, add explicit task-role secret ARN scopes in a user-owned environment and review them separately.

## Rotation considerations

Rotation is intentionally not automated here. Before real use, define:

- who creates initial values
- rotation frequency and emergency rotation process
- whether applications reload rotated values without restart
- rollback behavior for bad rotated values
- database credential rotation and migration sequencing
- KMS key ownership and audit requirements

## Public-safe local examples

Use `terraform.tfvars.example` only as shape documentation. It contains placeholder names and empty optional extra ARN lists. Do not copy real values into committed files.

Run validation with:

```bash
bash scripts/quality-gate.sh
```
