# Security

This project must not commit secrets, Terraform state, generated plans, cloud credentials, SSH keys, kubeconfigs, private data, or real account IDs.

Current local guardrails are validation-only and run through `bash scripts/quality-gate.sh`:

- `scripts/check-public-safety.sh` scans for local environment files, private key files/material, AWS credential-looking files/content, and non-placeholder 12-digit account IDs.
- `scripts/check-no-terraform-state.sh` rejects Terraform state, generated plan files, real `.tfvars` files, and local `.env` files.
- `scripts/check-no-cloud-mutations.sh` scans scripts and CI-style automation files for Terraform/cloud mutation commands.
- `scripts/check-terraform.sh` runs Terraform formatting and environment validation when Terraform is installed; otherwise it warns locally.

## Current infrastructure security posture

The network module separates public and private subnet intent:

- public subnets are for future internet-facing edge resources such as an ALB
- private subnets are for future ECS services, databases, and caches
- private subnets do not map public IP addresses on launch

The security-groups module now models explicit traffic boundaries:

- public IPv4 ingress is allowed only to the future ALB security group
- the ALB security group can reach the ECS service security group only on the configured service port
- ECS services can reach the PostgreSQL/RDS security group only on the configured database port
- ECS services can reach the Redis/ElastiCache security group only when Redis is enabled
- PostgreSQL and Redis security groups do not receive public CIDR ingress rules
- private data-store rules use security group references rather than broad VPC CIDR access

The IAM module now models role separation and secret-reference access:

- the ECS task execution role is trusted by `ecs-tasks.amazonaws.com` and receives the AWS-managed `AmazonECSTaskExecutionRolePolicy` for platform runtime needs
- the application ECS task role is separately trusted by `ecs-tasks.amazonaws.com` and receives no broad AWS permissions by default
- optional inline policies grant `secretsmanager:GetSecretValue`, `secretsmanager:DescribeSecret`, `ssm:GetParameter`, `ssm:GetParameters`, and optional `kms:Decrypt` only for supplied reference ARNs
- environment examples use fake account ID `123456789012` and placeholder Secrets Manager or SSM Parameter Store paths; no secret values are committed
- production use should review per-service task roles, exact ARN scoping, permissions boundaries, IAM Access Analyzer findings, KMS key policy alignment, and secret rotation ownership

The ECS service module now models private workload placement and secret injection boundaries:

- Fargate services run in private subnets with no public task IPs by default
- tasks use the private ECS service security group and receive traffic through ALB target groups only
- container images are constrained in examples to fake `public.ecr.aws/example/...:demo` URIs
- non-secret environment variables are separated from `secret_references`
- `secret_references` must be Secrets Manager or SSM Parameter Store ARNs, not secret values
- listener-rule creation is disabled until an ALB listener is explicitly wired by a later load-balancer module

The current egress model is intentionally strict and incomplete for real workloads. ECS services may need reviewed egress through VPC endpoints, NAT, or narrow rules for image pulls, logs, secret references, telemetry, and third-party APIs.

Future content will expand validation-only CI notes, secret lifecycle details, and production hardening gaps.
