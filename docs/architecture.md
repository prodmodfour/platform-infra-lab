# Architecture

This document is a living placeholder for the target AWS/Terraform architecture. Detailed diagrams and request flows are added in a later architecture ticket.

## Implemented so far

- `infra/terraform/modules/network` models the base VPC, public subnets, private subnets, an internet gateway, route tables, and an optional NAT gateway.
- `infra/terraform/environments/dev` wires the network module with two public/private subnet pairs and NAT disabled by default.
- `infra/terraform/environments/prod` wires the network module with three public/private subnet pairs and NAT enabled by default to demonstrate private egress intent.

## Target architecture themes

The broader public-safe container platform design will include an Application Load Balancer, ECS/Fargate services in private subnets, private PostgreSQL/RDS, optional private Redis/ElastiCache, IAM roles, secret references, and CloudWatch observability.

No private system names, real AWS account IDs, internal hostnames, or non-public architecture belong in this document.
