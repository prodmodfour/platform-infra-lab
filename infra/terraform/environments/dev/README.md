# Dev Terraform environment

This root module is the public-safe `dev` environment for `platform-infra-lab`. It establishes provider configuration, backend examples, variable defaults, outputs, naming, tagging, the shared network module, shared security-groups module, shared IAM module, shared load-balancer module, ECS/Fargate service examples, private RDS PostgreSQL example, and optional Redis cache example.

## Current scope

The dev environment now wires `../../modules/network` with cost-aware defaults:

- VPC CIDR: `10.20.0.0/16`
- two public subnets for the public Application Load Balancer edge
- two private subnets for ECS services, database, and cache resources
- internet gateway and public route table
- one private route table per private subnet
- NAT gateway disabled by default
- security groups for the public ALB, private ECS services, private PostgreSQL, and optional Redis cache
- public ingress limited to the ALB edge on HTTP by default
- an internet-facing Application Load Balancer with an HTTP listener and fixed-response default action
- optional HTTPS listener variables kept disabled until a user-owned ACM certificate ARN is supplied outside this repo
- optional ALB access-log wiring kept disabled by default because no real log bucket is committed
- private service-to-database rules scoped by security group reference rather than public CIDRs
- ECS task execution and application task IAM roles with placeholder secret-reference read policies
- a shared ECS cluster for private Fargate services
- ECS service examples for `carbon-platform-api`, `job-runner-platform`, and `multi-tenant-saas-api`
- fake public image URIs under `public.ecr.aws/example/...:demo`
- per-service CloudWatch log groups, task definitions, services, target groups, health checks, and desired-count autoscaling
- ALB listener rules that forward path patterns from the HTTP listener to each service target group
- fake Secrets Manager and SSM Parameter Store ARNs as references only; no secret values are stored
- a private RDS PostgreSQL instance in the private subnet group
- PostgreSQL public accessibility fixed to false
- RDS-managed Secrets Manager master user credential; no database password value is committed or read by this Terraform
- short dev backup retention, storage autoscaling ceiling, log exports, and disabled deletion protection/final snapshot for disposable lab experiments
- Redis/Valkey cache module wired with `enable_redis = false` by default, so no cache subnet group or replication group is created unless a user-owned experiment enables it
- small cache node shape, zero replicas, no snapshots, and encryption defaults documented for optional dev use
- CloudWatch observability module with a dev dashboard, ALB 5xx alarm, per-service unhealthy-target alarms, per-service ECS CPU/memory alarms, RDS CPU/free-storage alarms, and ECS log-group naming convention output
- empty alarm action lists by default; real paging or incident-routing ARNs must be supplied only outside this repo

Future tickets add secret-reference modeling details, CI, diagrams, and fuller operating documentation.

## Dev posture

Dev is intentionally small and cost-aware:

- two availability zones are shown for the platform pattern
- NAT gateway usage defaults to disabled until private egress is explicitly needed
- log retention defaults to a short demo-friendly window for future log groups
- deletion protection defaults to disabled for disposable lab experiments
- Redis/cache usage defaults to disabled, so the Redis security group and ElastiCache resources are omitted by default
- PostgreSQL uses a small single-AZ instance class, short backup retention, encrypted gp3 storage, and no public accessibility
- default ECS desired count is one task for each service example
- autoscaling ranges are intentionally small for review
- observability thresholds are visible variables, with empty alarm action lists to avoid committing real routing ARNs
- placeholder IAM and container secret-reference scopes use dev paths and a fake account ID for review only

These are placeholders for review and validation, not a production recommendation.

## Network review notes

Public subnets are intended for internet-facing components only. Private subnets are intended for workloads and stateful services that should not receive public IP addresses.

The security group boundary is intentionally narrow: internet CIDRs reach only the ALB security group, the ALB reaches ECS services only on the service port through listener rules and target groups, ECS services reach PostgreSQL only on port 5432, and Redis rules/resources are created only when Redis is enabled. No public database or cache ingress is modeled. The RDS PostgreSQL module consumes the private RDS security group and private subnets, and fixes `publicly_accessible = false`. The Redis cache module consumes private subnets and the private Redis security group only when enabled.

The IAM boundary separates the ECS task execution role from the application task role. The execution role is for ECS runtime integration such as image pulls, log delivery, and ECS-managed secret injection. The application task role starts with only explicitly supplied secret-reference read permissions. ECS service examples pass secret references as ARNs only, never values. All example ARNs are placeholders and must be replaced or removed before any real manual provisioning.

If NAT is enabled for a real dev experiment, it can create ongoing cloud cost. Keep it disabled unless the workload needs private outbound internet access, and clean up user-owned resources after review. Real workloads may also need reviewed egress through VPC endpoints, NAT, or narrow outbound rules for image pulls, logging, secret references, and AWS APIs.

## Public-safety notes

- `backend.example.tf` uses fake placeholder bucket and lock-table names.
- `terraform.tfvars.example` contains only placeholder values.
- Do not commit real `.tfvars`, Terraform state, generated plans, credentials, SSH keys, kubeconfigs, or `.env` files.
- Any future manual provisioning is optional, user-owned, and can incur cloud cost. This repository does not automate provisioning.

## Validation

From the repository root, run:

```bash
bash scripts/quality-gate.sh
```

When Terraform is installed, the guardrail validates this environment with backend access disabled so no cloud account is required for validation.
