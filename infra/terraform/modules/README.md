# Terraform module conventions

This directory contains reusable Terraform modules for the AWS platform lab. Module directories are added ticket-by-ticket; this file defines the conventions every module should follow.

## Implemented modules

- `network` — VPC, public/private subnets, route tables, an internet gateway, and an optional NAT gateway for private subnet egress.
- `security-groups` — ALB, ECS service, PostgreSQL/RDS, and optional Redis/ElastiCache security group boundaries.
- `iam` — ECS task execution role, application task role, and optional read policies for Secrets Manager or SSM Parameter Store references.
- `load-balancer` — public Application Load Balancer, HTTP listener, optional HTTPS listener variables, optional access-log references, and listener outputs for ECS service rules.
- `ecs-service` — ECS/Fargate task definition, service, CloudWatch log group, ALB target group, listener rule, health checks, and desired-count autoscaling.
- `rds-postgres` — private RDS PostgreSQL instance, subnet group, backup/deletion-protection settings, storage variables, log exports, and RDS-managed Secrets Manager master credentials.
- `redis-cache` — optional private ElastiCache Redis/Valkey-style replication group, subnet group, encryption settings, replica/Multi-AZ variables, snapshots, and disabled outputs when not enabled.
- `observability` — CloudWatch dashboard, ALB 5xx and unhealthy-target alarms, ECS CPU/memory alarms, RDS CPU/free-storage alarms, and ECS log-group naming conventions.

These names are public-safe design labels, not references to private systems.

## Required module structure

Each module must include:

```text
<module>/
├── main.tf
├── variables.tf
├── outputs.tf
└── README.md
```

Keep modules focused. A module should model one reviewable infrastructure concern rather than hiding an entire platform behind a broad interface.

## Module interface conventions

Module interfaces should be explicit and stable.

Inputs should:

- use typed variables with clear descriptions
- include validation blocks where they improve safety or readability
- accept `environment` and `common_tags` when resources are environment-scoped
- accept dependency IDs or ARNs from the environment root, such as VPC IDs, subnet IDs, security group IDs, listener ARNs, and secret reference ARNs
- use safe defaults only when the default is genuinely safe for a public example
- mark sensitive values with `sensitive = true` if Terraform must receive them
- prefer secret references over secret values

Outputs should:

- expose only values needed by environments or downstream modules
- use predictable names such as `vpc_id`, `private_subnet_ids`, `security_group_id`, `cluster_arn`, or `log_group_name`
- avoid outputting secret values or credentials
- include descriptions for reviewability

Modules should not:

- configure a Terraform backend
- hard-code AWS account IDs, private domains, private hostnames, real bucket names, or real secret ARNs
- create resources by default that are unrelated to the module purpose
- depend on local files containing secrets or operator-specific values
- run provisioners or local commands that mutate cloud infrastructure

## Naming and tags

Modules should accept a name input such as `name` or `name_prefix` and leave environment-specific naming decisions to the environment root.

Recommended module inputs:

```hcl
variable "name_prefix" {
  description = "Public-safe prefix used for named resources."
  type        = string
}

variable "environment" {
  description = "Environment name such as dev or prod."
  type        = string
}

variable "common_tags" {
  description = "Common tags applied to taggable resources."
  type        = map(string)
  default     = {}
}
```

Resource tags should merge `common_tags` with module-specific tags, for example a generic `Component` tag. Tags must not contain secrets, private names, or real account identifiers.

## Security expectations

Every module README should explain the security boundary it models. Examples:

- network modules distinguish public and private subnet intent
- security group resources keep database and cache ingress private
- ECS modules separate task execution role needs from application task role permissions
- RDS and Redis modules avoid public accessibility by default
- secret-related inputs accept references, not committed values

Least-privilege intent should be visible in variables, IAM policy scope, and security group wiring. Production hardening gaps should be called out instead of hidden.

## Cost expectations

Every module README should identify qualitative cost drivers without claiming exact current prices. Examples include NAT gateways, load balancers, Fargate CPU/memory, database instance class, storage, log retention, alarms, and cache node counts.

Modules should expose cost-aware sizing variables where practical so dev examples can stay small while prod examples can show stronger availability or retention.

## Validation expectations

Module code must pass:

```bash
terraform fmt -recursive -check
```

Environment validation is run from `infra/terraform/environments/*` with backend access disabled. Modules should therefore avoid assumptions that require live cloud credentials just to parse or validate configuration.
