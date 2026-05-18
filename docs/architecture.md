# Architecture

This document is a living placeholder for the target AWS/Terraform architecture. Detailed diagrams and request flows are added in a later architecture ticket.

## Implemented so far

- `infra/terraform/modules/network` models the base VPC, public subnets, private subnets, an internet gateway, route tables, and an optional NAT gateway.
- `infra/terraform/modules/security-groups` models public ALB, private ECS service, private PostgreSQL/RDS, and optional private Redis/ElastiCache security group boundaries.
- `infra/terraform/modules/iam` models the ECS task execution role, application task role, and optional read policies for secret references.
- `infra/terraform/environments/dev` wires the network, security-groups, and IAM modules with two public/private subnet pairs, NAT disabled by default, Redis security groups disabled by default, and dev-scoped placeholder secret-reference ARNs.
- `infra/terraform/environments/prod` wires the network, security-groups, and IAM modules with three public/private subnet pairs, NAT enabled by default to demonstrate private egress intent, Redis security groups enabled to show the optional cache tier, and prod-scoped placeholder secret-reference ARNs.

## Target architecture themes

The broader public-safe container platform design will include an Application Load Balancer, ECS/Fargate services in private subnets, private PostgreSQL/RDS, optional private Redis/ElastiCache, secret references, and CloudWatch observability.

Current IAM intent:

- the ECS task execution role is reserved for ECS runtime integration, including image pulls, log delivery, and ECS-managed secret injection
- the application task role is separate and starts with only explicitly supplied secret-reference read permissions
- secret policies use variable-provided Secrets Manager and SSM Parameter Store ARNs, plus optional KMS key ARNs, rather than committed secret values
- example ARNs use a fake account ID and placeholder paths only

Current security group intent:

- public internet CIDRs reach only the future ALB security group
- the ALB security group reaches the ECS service security group only on the application service port
- the ECS service security group reaches PostgreSQL only on the database port
- the ECS service security group reaches Redis only when the Redis boundary is enabled
- database and cache security groups have no public ingress rules

No private system names, real AWS account IDs, internal hostnames, or non-public architecture belong in this document.
