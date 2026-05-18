# 0001 — AWS ECS/Fargate as the container platform

## Status

Accepted.

## Context

`platform-infra-lab` needs to demonstrate a reviewable AWS container platform for backend services without copying application code or requiring a live deployment. The reference services (`carbon-platform-api`, `job-runner-platform`, and `multi-tenant-saas-api`) need a realistic home for HTTP routing, private networking, IAM role separation, secret references, logs, metrics, alarms, and operational runbooks.

The project also needs to stay approachable for portfolio reviewers. A platform based on ECS/Fargate is easier to inspect in a Terraform lab than a full Kubernetes control plane, while still showing production-relevant AWS patterns such as Application Load Balancers, target groups, Fargate task definitions, service health checks, CloudWatch observability, and task roles.

## Decision

Use AWS ECS on Fargate as the modeled container runtime.

The Terraform environments create an ECS cluster and instantiate the shared ECS service module for the three public-safe demo services. Services run in private subnets, do not receive public task IPs, and receive traffic through an internet-facing Application Load Balancer with explicit listener rules and target groups.

The repository remains infrastructure-only:

- fake images under `public.ecr.aws/example/...:demo` are used for examples
- application source code is intentionally not included
- CI and local scripts validate Terraform and guardrails only
- any real provisioning is optional, manual, user-owned, and cost-bearing

## Consequences

This decision demonstrates common backend/platform/SRE skills: ECS/Fargate service design, ALB routing, health checks, private service placement, IAM execution/task role separation, and CloudWatch operations.

Fargate reduces the amount of host-level infrastructure that the lab must model, but it also means the project does not demonstrate Kubernetes operations, node lifecycle management, daemon scheduling, or deep EC2 capacity tuning. Those are intentionally out of scope for this portfolio repository.

If a user adapts the lab for real use, they must still review production concerns such as TLS and DNS, WAF/rate limiting, image provenance, vulnerability scanning, VPC endpoint or NAT egress strategy, per-service IAM scoping, autoscaling thresholds, incident routing, and cost controls. Fargate tasks, load balancers, logs, alarms, and related resources can incur cost when manually provisioned.
