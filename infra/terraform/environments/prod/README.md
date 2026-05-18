# Prod Terraform environment

This root module is the public-safe `prod` environment for `platform-infra-lab`. It mirrors the dev structure while using production-intent defaults and examples for review, including the shared network, security-groups, IAM, load-balancer, ECS service, and RDS PostgreSQL modules.

## Current scope

The prod environment now wires `../../modules/network` with production-intent defaults:

- VPC CIDR: `10.30.0.0/16`
- three public subnets for the public Application Load Balancer edge
- three private subnets for ECS services, database, and cache resources
- internet gateway and public route table
- one private route table per private subnet
- one shared NAT gateway enabled by default to demonstrate private egress
- security groups for the public ALB, private ECS services, private PostgreSQL, and optional Redis cache
- public ingress limited to the ALB edge on HTTP by default
- an internet-facing Application Load Balancer with an HTTP listener and fixed-response default action
- optional HTTPS listener variables kept disabled until a user-owned ACM certificate ARN is supplied outside this repo
- optional ALB access-log wiring kept disabled by default because no real log bucket is committed
- private service-to-database and service-to-cache rules scoped by security group reference rather than public CIDRs
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
- production-intent PostgreSQL settings including Multi-AZ, longer backup retention, deletion protection, final snapshot, larger storage ceiling, log exports, and Performance Insights enabled

Future tickets add Redis resources and observability.

## Prod posture

Prod demonstrates production intent rather than production completeness:

- three availability zones are shown for review of multi-AZ layout
- NAT gateway usage defaults to enabled to model private egress needs
- log retention defaults to a longer window than dev for future log groups
- deletion protection defaults to enabled for future stateful services
- Redis/cache usage defaults to enabled to show the optional private cache tier and security group boundary
- ALB deletion protection defaults to enabled to show production-intent review posture, while still requiring user-owned cleanup planning
- PostgreSQL deletion protection, Multi-AZ, final snapshot, non-zero backup retention, encrypted gp3 storage, and Performance Insights are enabled to show production intent
- default ECS desired count is two tasks for each service example
- autoscaling ranges are wider than dev to show production-intent capacity planning
- placeholder IAM and container secret-reference scopes use prod paths and a fake account ID for review only

These settings can create ongoing cost if a user later provisions real infrastructure. Any real use must be reviewed, user-owned, and cleaned up by the operator.

## Network review notes

Public subnets are intended for internet-facing components only. Private subnets are intended for workloads and stateful services that should not receive public IP addresses.

The security group boundary is intentionally narrow: internet CIDRs reach only the ALB security group, the ALB reaches ECS services only on the service port through listener rules and target groups, ECS services reach PostgreSQL only on port 5432, and ECS services reach Redis only when Redis is enabled. No public database or cache ingress is modeled. The RDS PostgreSQL module consumes the private RDS security group and private subnets, and fixes `publicly_accessible = false`.

The IAM boundary separates the ECS task execution role from the application task role. The execution role is for ECS runtime integration such as image pulls, log delivery, and ECS-managed secret injection. The application task role starts with only explicitly supplied secret-reference read permissions. ECS service examples pass secret references as ARNs only, never values. All example ARNs are placeholders and must be replaced or removed before any real manual provisioning.

The prod example uses a single shared NAT gateway to keep the pattern readable. A real production design should review per-availability-zone NAT gateways, VPC endpoints, flow logs, CIDR sizing, regional availability-zone support, HTTPS-only ingress, WAF/trusted CIDR controls, IAM permissions boundaries, per-service task roles, and outbound access requirements before provisioning.

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
