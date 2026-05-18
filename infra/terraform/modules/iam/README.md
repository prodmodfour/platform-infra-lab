# IAM module

This module models the IAM boundary for ECS/Fargate workloads in the public-safe platform lab. It creates separate roles for ECS runtime actions and application runtime permissions, then attaches optional least-privilege policies for approved secret references.

## Resources

- `aws_iam_role.task_execution` — ECS task execution role trusted by `ecs-tasks.amazonaws.com`.
- `aws_iam_role.task` — application task role trusted by `ecs-tasks.amazonaws.com`.
- `aws_iam_role_policy_attachment.task_execution_managed_policy` — attaches AWS's managed `AmazonECSTaskExecutionRolePolicy` to the execution role for standard ECS runtime needs such as image pulls and log delivery.
- `aws_iam_role_policy.execution_secret_references` — optional inline policy for ECS-managed container secret injection when execution secret/parameter references are supplied.
- `aws_iam_role_policy.task_secret_references` — optional inline policy for application code to read explicitly approved secret/parameter references.

## Task role versus execution role

The module intentionally separates the two ECS IAM roles:

| Role | Used by | Typical permissions in this lab |
| --- | --- | --- |
| Task execution role | ECS agent / Fargate runtime | Pull container images, create/write logs, resolve ECS task-definition secret references. |
| Task role | Application code running in the container | Only application AWS API calls that are explicitly granted, such as reading approved secret references. |

Keeping these roles separate makes review easier: platform runtime permissions do not automatically become application permissions, and application access can be scoped to the smallest set of required resources.

## Secret references, not values

This module never accepts or stores secret values. It accepts only ARNs for AWS Secrets Manager secrets, optional SSM Parameter Store parameters, and optional KMS keys. Environment roots now feed it Secrets Manager ARNs from the metadata-only `secrets-manager-references` module plus any explicitly supplied additional user-owned references.

Example placeholder references are safe for this public repo:

```hcl
execution_secret_reference_arns = [
  "arn:aws:secretsmanager:us-east-1:123456789012:secret:platform-infra-lab/dev/ecs-execution/*",
]

task_secret_reference_arns = [
  "arn:aws:secretsmanager:us-east-1:123456789012:secret:platform-infra-lab/dev/application/*",
]
```

The example account ID is fake. Real secret values should be created and rotated outside this repository or by a secure user-owned pipeline.

## Inputs

Key inputs:

- `name_prefix` — public-safe prefix for role and policy names.
- `environment` — environment label used in tags.
- `execution_secret_reference_arns` — Secrets Manager ARNs the ECS runtime may read for container secret injection.
- `execution_ssm_parameter_arns` — SSM parameter ARNs the ECS runtime may read for container secret injection.
- `execution_kms_key_arns` — optional KMS key ARNs for execution-role decrypt access.
- `task_secret_reference_arns` — Secrets Manager ARNs application code may read through the task role.
- `task_ssm_parameter_arns` — SSM parameter ARNs application code may read through the task role.
- `task_kms_key_arns` — optional KMS key ARNs for application-role decrypt access.
- `common_tags` — public-safe tags merged into IAM role tags.

The module validates that secret and parameter inputs are ARNs rather than raw values and rejects the full wildcard resource `*`.

## Outputs

- `ecs_task_execution_role_name`
- `ecs_task_execution_role_arn`
- `ecs_task_role_name`
- `ecs_task_role_arn`
- `execution_secret_policy_name`
- `task_secret_policy_name`
- `secret_reference_policy_summary`
- `iam_role_summary`

Outputs include resource identifiers and secret-reference ARNs only. They do not include secret values.

## Security notes

- The execution role and application task role have different responsibilities.
- The application task role starts with no broad AWS permissions.
- Secret-read policies are created only when reference ARN inputs are supplied.
- Policies scope reads to the supplied Secrets Manager, SSM Parameter Store, and KMS ARNs instead of using account-wide `*` resources.
- This module does not create secret values or parameters. It only models IAM access to references created by the metadata-only Secrets Manager module or supplied from a user-owned environment.

## Cost notes

IAM roles and inline policies do not have standalone hourly cost. The services that consume them can incur cost, such as ECS/Fargate tasks, CloudWatch Logs, Secrets Manager, SSM Parameter Store advanced parameters, and KMS requests. Any optional manual provisioning remains user-owned and should be reviewed before use.

## Production review requirements

Before real production use, review:

- whether each service should have its own task role instead of sharing an environment-level role
- whether placeholder path wildcards should be replaced with exact secret or parameter ARNs
- customer-managed KMS key requirements and `kms:Decrypt` scope
- permissions boundaries, service control policies, and IAM Access Analyzer findings
- CloudWatch Logs, ECR, Secrets Manager, and SSM access paths through VPC endpoints or reviewed NAT egress
- rotation ownership for every referenced secret
- whether application permissions need additional least-privilege policies beyond secret reads

## Validation

Run from the repository root:

```bash
bash scripts/quality-gate.sh
```

Terraform validation uses `terraform init -backend=false` and does not require a real backend or cloud mutation.
