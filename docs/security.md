# Security

This project must not commit secrets, Terraform state, generated plans, cloud credentials, SSH keys, kubeconfigs, private data, or real account IDs.

Current local guardrails are validation-only and run through `bash scripts/quality-gate.sh`:

- `scripts/check-public-safety.sh` scans for local environment files, private key files/material, AWS credential-looking files/content, and non-placeholder 12-digit account IDs.
- `scripts/check-no-terraform-state.sh` rejects Terraform state, generated plan files, real `.tfvars` files, and local `.env` files.
- `scripts/check-no-cloud-mutations.sh` scans scripts and CI-style automation files for Terraform/cloud mutation commands.
- `scripts/check-terraform.sh` runs Terraform formatting and environment validation when Terraform is installed; otherwise it warns locally.

## Current infrastructure security posture

The network module separates public and private subnet intent:

- public subnets are for internet-facing edge resources such as the ALB
- private subnets are for ECS services, databases, and caches
- private subnets do not map public IP addresses on launch

The load-balancer module now models the public edge:

- the ALB is internet-facing by default and uses the dedicated ALB security group
- the HTTP listener has a fixed-response default action for unmatched routes
- ECS services attach path-based listener rules to the ALB listener and stay in private subnets
- optional HTTPS support requires a user-owned ACM certificate ARN outside this repo; no real certificate ARN is committed
- optional access logs require a user-owned S3 bucket outside this repo; no real bucket is committed

The security-groups module now models explicit traffic boundaries:

- public IPv4 ingress is allowed only to the ALB security group
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
- listener rules are wired to the load-balancer module HTTP listener by default, keeping route ownership explicit

The RDS PostgreSQL module now models the private database boundary:

- the DB subnet group uses private subnet IDs from the network module
- `publicly_accessible` is fixed to `false`
- the environment passes only the private RDS security group, whose ingress is scoped to ECS services on the PostgreSQL port
- the module does not accept or output a database password value
- RDS-managed master user password support stores the master credential in Secrets Manager if a user manually provisions the lab
- outputs expose the RDS-managed secret ARN as a reference only, not the secret value
- dev and prod examples keep KMS key inputs null so no real key ARN is committed

The Redis cache module now models the private cache boundary:

- the ElastiCache subnet group uses private subnet IDs from the network module
- cache resources are created only when `enable_redis` is true
- the environment passes only the private Redis security group, whose ingress is scoped to ECS services on the Redis port
- at-rest and in-transit encryption default to enabled
- KMS key inputs stay null in committed examples so no real key ARN is committed
- cache endpoint outputs are references only and are not credentials
- no Redis AUTH token, ACL user group, or cache connection-string secret value is stored in Terraform

The observability module now models CloudWatch visibility without committing private routing details:

- dashboard widgets consume resource names, ARN suffixes, metric dimensions, and log group names only
- ECS service logs follow a public-safe naming convention and are referenced by dashboard widgets; log contents are not stored in this repo
- alarms cover ALB 5xx responses, unhealthy targets, ECS CPU/memory, and RDS CPU/free storage
- alarm action lists default to empty so no real SNS topic ARN, account ID, webhook, or incident-routing target is committed
- production use should review log access, retention, redaction, dashboard permissions, paging routes, and runbook ownership

The current egress model is intentionally strict and incomplete for real workloads. ECS services may need reviewed egress through VPC endpoints, NAT, or narrow rules for image pulls, logs, secret references, telemetry, and third-party APIs. Real database use also needs reviewed migration roles, least-privilege database users, connection pooling, audit logging, and secret rotation ownership. Real cache use should review Redis AUTH/ACLs, TLS client compatibility, cache parameter groups, eviction policy, and whether cached data includes tenant-sensitive or regulated content.

Future content will expand validation-only CI notes, secret lifecycle details, and production hardening gaps.
