# Dev Terraform environment

This root module is the public-safe `dev` environment for `platform-infra-lab`. It establishes provider configuration, backend examples, variable defaults, outputs, naming, tagging, the shared network module, shared security-groups module, and shared IAM module.

## Current scope

The dev environment now wires `../../modules/network` with cost-aware defaults:

- VPC CIDR: `10.20.0.0/16`
- two public subnets for future public edge resources such as an ALB
- two private subnets for future ECS services, database, and cache resources
- internet gateway and public route table
- one private route table per private subnet
- NAT gateway disabled by default
- security groups for the future public ALB, private ECS services, private PostgreSQL, and optional Redis cache
- public ingress limited to the future ALB edge on HTTP by default
- private service-to-database rules scoped by security group reference rather than public CIDRs
- ECS task execution and application task IAM roles with placeholder secret-reference read policies
- fake Secrets Manager and SSM Parameter Store ARNs as references only; no secret values are stored

Future tickets add ECS service patterns, load balancing, RDS PostgreSQL, optional Redis resources, and observability.

## Dev posture

Dev is intentionally small and cost-aware:

- two availability zones are shown for the platform pattern
- NAT gateway usage defaults to disabled until private egress is explicitly needed
- log retention defaults to a short demo-friendly window for future log groups
- deletion protection defaults to disabled for disposable lab experiments
- Redis/cache usage defaults to disabled, so the Redis security group is omitted by default
- default ECS desired count is one task for future service examples
- placeholder IAM secret-reference scopes use dev paths and a fake account ID for review only

These are placeholders for review and validation, not a production recommendation.

## Network review notes

Public subnets are intended for internet-facing components only. Private subnets are intended for workloads and stateful services that should not receive public IP addresses.

The security group boundary is intentionally narrow: internet CIDRs reach only the ALB security group, the ALB reaches ECS services only on the service port, ECS services reach PostgreSQL only on port 5432, and Redis rules are created only when Redis is enabled. No public database or cache ingress is modeled.

The IAM boundary separates the ECS task execution role from the application task role. The execution role is for ECS runtime integration such as image pulls, log delivery, and ECS-managed secret injection. The application task role starts with only explicitly supplied secret-reference read permissions. All example ARNs are placeholders and must be replaced or removed before any real manual provisioning.

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
