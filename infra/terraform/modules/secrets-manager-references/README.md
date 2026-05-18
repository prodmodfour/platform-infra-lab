# Secrets Manager references module

This module models the repository's secret-reference pattern with AWS Secrets Manager while keeping secret values out of Terraform code, examples, outputs, and state.

It creates Secrets Manager **secret metadata containers only**. It deliberately does not create `aws_secretsmanager_secret_version`, does not accept `secret_string`, and does not generate or store secret values.

## Resources

- `aws_secretsmanager_secret.ecs_execution` — metadata-only secret containers for ECS task-definition secret injection.

## Secret references, not values

The module turns public-safe metadata such as this:

```hcl
ecs_execution_secret_definitions = {
  carbon-platform-api = {
    DATABASE_URL = {
      secret_name = "database-url"
      description = "Placeholder database URL reference. Value is created outside this repo."
    }
  }
}
```

into Secrets Manager ARNs that the ECS service module can pass to container `secrets` blocks:

```hcl
secret_references = module.secrets_manager_references.ecs_secret_references_by_service["carbon-platform-api"]
```

At runtime, ECS resolves the ARN through the task execution role and injects the secret into the container environment variable. The application receives the secret value from ECS, but this repository stores only the reference.

## Value ownership

Secret values should be created outside this repository or by a secure user-owned pipeline. Examples include a reviewed CI/CD secret bootstrap process, an operator-owned secrets workflow, or a separate private automation stack.

This module is intentionally limited to metadata and references:

- no committed secret values
- no `aws_secretsmanager_secret_version` resources
- no generated passwords in Terraform state
- no local `.tfvars` files with real values
- no CLI or CI step that writes secrets

## IAM wiring

Environment roots pass `ecs_execution_secret_arns` into the IAM module so the ECS task execution role can read only the approved Secrets Manager references. The application task role does not need direct `secretsmanager:GetSecretValue` permission when ECS injects secrets into the container.

If a real service reads secrets directly with the AWS SDK instead of ECS injection, add explicit task-role secret ARN inputs in the environment and review them separately.

## Rotation considerations

This module does not configure rotation schedules because real rotation needs application-specific testing, ownership, rollback planning, and sometimes a rotation Lambda. For production use, review:

- which system owns initial value creation
- rotation frequency and emergency rotation triggers
- whether applications reload rotated values safely
- database user rotation strategy and migration timing
- rollback behavior if a rotated value breaks a deployment
- customer-managed KMS key and key-policy requirements

## Inputs

Key inputs:

- `secret_path_prefix` — public-safe prefix such as `platform-infra-lab/dev`.
- `ecs_execution_secret_definitions` — service/environment-variable metadata for ECS-injected references.
- `kms_key_id` — optional user-owned KMS key identifier; committed examples keep this null.
- `recovery_window_in_days` — Secrets Manager deletion recovery window.
- `common_tags` — public-safe tags for review, cleanup, and ownership.

## Outputs

- `ecs_secret_references_by_service`
- `ecs_execution_secret_arns`
- `ecs_secret_names_by_service`
- `secret_metadata_summary`
- `value_management_summary`

Outputs include names, ARNs, and summaries only. They never include secret values.

## Cost notes

Secrets Manager can incur ongoing cost per secret and per API usage when manually provisioned. KMS requests may add cost if customer-managed keys are used. This repository does not claim exact current prices; optional manual provisioning is user-owned and can incur cost.

## Production hardening gaps

Before real production use, review:

- per-service task execution roles instead of a shared environment role
- exact secret ARN scoping and path conventions
- customer-managed KMS keys, key policies, and grants
- VPC endpoints or reviewed NAT egress for private ECS secret resolution
- rotation ownership and testing
- whether secret names reveal sensitive business context
- secret access auditing and alerting
- deletion recovery windows and break-glass recovery procedures

## Validation

Run from the repository root:

```bash
bash scripts/quality-gate.sh
```

Terraform validation uses `terraform init -backend=false` and does not require a real backend or cloud mutation.
