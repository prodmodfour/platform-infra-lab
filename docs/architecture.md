# Architecture

This document is a living placeholder for the target AWS/Terraform architecture. Detailed diagrams and request flows are added in a later architecture ticket.

## Implemented so far

- `infra/terraform/modules/network` models the base VPC, public subnets, private subnets, an internet gateway, route tables, and an optional NAT gateway.
- `infra/terraform/modules/security-groups` models public ALB, private ECS service, private PostgreSQL/RDS, and optional private Redis/ElastiCache security group boundaries.
- `infra/terraform/modules/iam` models the ECS task execution role, application task role, and optional read policies for secret references.
- `infra/terraform/modules/load-balancer` models an internet-facing Application Load Balancer, required HTTP listener, optional HTTPS listener variables, optional access-log references, and listener outputs for service rules.
- `infra/terraform/modules/ecs-service` models a private Fargate service with task definition, ECS service, CloudWatch log group, ALB target group, listener rule, health checks, and desired-count autoscaling.
- `infra/terraform/modules/rds-postgres` models a private RDS PostgreSQL instance with a private DB subnet group, no public accessibility, backup/deletion-protection settings, storage variables, log exports, optional monitoring settings, and RDS-managed Secrets Manager master credentials.
- `infra/terraform/modules/redis-cache` models an optional private ElastiCache Redis/Valkey-style replication group with a private subnet group, private security group input, enable/disable behavior, encryption settings, snapshots, and replica/Multi-AZ variables.
- `infra/terraform/environments/dev` wires the network, security-groups, IAM, load-balancer, ECS service, RDS PostgreSQL, and Redis cache modules with two public/private subnet pairs, NAT disabled by default, Redis resources disabled by default, one task per demo service, a small single-AZ private PostgreSQL instance, dev-scoped placeholder secret-reference ARNs, and fake service images.
- `infra/terraform/environments/prod` wires the network, security-groups, IAM, load-balancer, ECS service, RDS PostgreSQL, and Redis cache modules with three public/private subnet pairs, NAT enabled by default to demonstrate private egress intent, Redis resources enabled to show the optional cache tier with one replica/Multi-AZ intent, two tasks per demo service, a Multi-AZ private PostgreSQL instance with deletion protection, prod-scoped placeholder secret-reference ARNs, and fake service images.

## Target architecture themes

The broader public-safe container platform design includes an Application Load Balancer, ECS/Fargate services in private subnets, private PostgreSQL/RDS, optional private Redis/ElastiCache, secret references, and CloudWatch observability.

Current load-balancer intent:

- the ALB is the only public edge resource and is placed in public subnets
- the HTTP listener returns a fixed response for unmatched routes
- each ECS service owns a target group and listener rule with explicit path patterns
- optional HTTPS variables exist, but committed examples keep HTTPS disabled because no real certificate ARN belongs in this repo
- optional access-log wiring references a user-owned bucket only when enabled; no real bucket is committed

Current ECS service intent:

- a shared ECS cluster exists per environment
- `carbon-platform-api`, `job-runner-platform`, and `multi-tenant-saas-api` are modeled as private Fargate services
- each service uses a fake `public.ecr.aws/example/...:demo` image and no application code is copied into this repo
- task definitions use the execution role for image pulls, log delivery, and ECS-managed secret injection, plus a separate application task role
- each service has a CloudWatch log group, target group, target-group health check, container health check, deployment circuit breaker, listener rule, and autoscaling settings
- listener rules use the load-balancer module's HTTP listener ARN by default and forward service path patterns to private Fargate target groups

Current IAM intent:

- the ECS task execution role is reserved for ECS runtime integration, including image pulls, log delivery, and ECS-managed secret injection
- the application task role is separate and starts with only explicitly supplied secret-reference read permissions
- secret policies use variable-provided Secrets Manager and SSM Parameter Store ARNs, plus optional KMS key ARNs, rather than committed secret values
- example ARNs use a fake account ID and placeholder paths only

Current RDS PostgreSQL intent:

- the database subnet group uses private subnets only
- the RDS instance fixes `publicly_accessible = false`
- the RDS security group accepts PostgreSQL only from the ECS service security group
- RDS manages the master user password in Secrets Manager, and Terraform only exposes the secret ARN as a reference
- dev uses small single-AZ sizing and shorter backup retention for cost-aware review
- prod shows production intent with Multi-AZ, deletion protection, final snapshot, longer backup retention, and Performance Insights enabled

Current Redis/Valkey cache intent:

- the cache subnet group uses private subnets only
- the cache security group accepts Redis only from the ECS service security group
- the module is disabled in dev by default to avoid unnecessary lab cost
- prod enables a small private replication group with one replica, automatic failover, Multi-AZ, at-rest encryption, in-transit encryption, snapshot retention, and a final snapshot identifier
- endpoint outputs are references for application configuration and review, not credentials
- no Redis AUTH token or ACL secret value is stored in Terraform; secure secret-reference wiring is deferred to the dedicated secrets ticket

Current security group intent:

- public internet CIDRs reach only the ALB security group
- the ALB security group reaches the ECS service security group only on the application service port
- the ECS service security group reaches PostgreSQL only on the database port
- the ECS service security group reaches Redis only when the Redis boundary is enabled
- database and cache security groups have no public ingress rules

No private system names, real AWS account IDs, internal hostnames, or non-public architecture belong in this document.
