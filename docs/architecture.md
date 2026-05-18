# Architecture

This document is a living placeholder for the target AWS/Terraform architecture. Detailed diagrams and request flows are added in a later architecture ticket.

## Implemented so far

- `infra/terraform/modules/network` models the base VPC, public subnets, private subnets, an internet gateway, route tables, and an optional NAT gateway.
- `infra/terraform/modules/security-groups` models public ALB, private ECS service, private PostgreSQL/RDS, and optional private Redis/ElastiCache security group boundaries.
- `infra/terraform/modules/iam` models the ECS task execution role, application task role, and optional read policies for secret references.
- `infra/terraform/modules/ecs-service` models a private Fargate service with task definition, ECS service, CloudWatch log group, ALB target group, optional listener rule, health checks, and desired-count autoscaling.
- `infra/terraform/environments/dev` wires the network, security-groups, IAM, and ECS service modules with two public/private subnet pairs, NAT disabled by default, Redis security groups disabled by default, one task per demo service, dev-scoped placeholder secret-reference ARNs, and fake service images.
- `infra/terraform/environments/prod` wires the network, security-groups, IAM, and ECS service modules with three public/private subnet pairs, NAT enabled by default to demonstrate private egress intent, Redis security groups enabled to show the optional cache tier, two tasks per demo service, prod-scoped placeholder secret-reference ARNs, and fake service images.

## Target architecture themes

The broader public-safe container platform design will include an Application Load Balancer, ECS/Fargate services in private subnets, private PostgreSQL/RDS, optional private Redis/ElastiCache, secret references, and CloudWatch observability.

Current ECS service intent:

- a shared ECS cluster exists per environment
- `carbon-platform-api`, `job-runner-platform`, and `multi-tenant-saas-api` are modeled as private Fargate services
- each service uses a fake `public.ecr.aws/example/...:demo` image and no application code is copied into this repo
- task definitions use the execution role for image pulls, log delivery, and ECS-managed secret injection, plus a separate application task role
- each service has a CloudWatch log group, target group, target-group health check, container health check, deployment circuit breaker, and autoscaling settings
- listener-rule creation is optional and disabled until the load-balancer module supplies an ALB listener ARN

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
