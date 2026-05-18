# ECS service module

This module models one private ECS/Fargate backend service for the public-safe platform lab.

It is intentionally focused on the service deployment pattern, not application code. Example images must stay fake public placeholders such as `public.ecr.aws/example/carbon-platform-api:demo`.

## What it creates

- CloudWatch log group for the service container
- ALB target group using `target_type = "ip"` for Fargate tasks
- optional ALB listener rule that forwards path patterns to the target group
- ECS task definition with one application container
- ECS service using Fargate, private subnets, and the supplied ECS service security group
- ECS deployment circuit breaker configuration
- optional target-tracking Application Auto Scaling policies for desired count

The module accepts an existing ECS cluster ARN/name rather than creating a cluster per service. Environment roots create the shared cluster and instantiate this module once per demo service.

## Security intent

- Fargate tasks run in private subnets with `assign_public_ip = false` by default.
- The service uses security group IDs passed by the environment root, normally the private ECS service security group from `modules/security-groups`.
- Public ingress is not created here. Traffic reaches the service through an ALB target group and, when enabled, an ALB listener rule.
- The task execution role and application task role are passed in separately to preserve IAM role separation.
- Container `environment_variables` are for non-secret values only.
- Container `secret_references` are Secrets Manager or SSM Parameter Store ARNs only; secret values are never accepted or output.

## Load-balancer wiring

The module always creates a target group and attaches the ECS service to it through the ECS `load_balancer` block. It can also create a listener rule when a listener ARN is supplied:

```hcl
create_listener_rule     = true
listener_arn             = module.load_balancer.http_listener_arn
listener_rule_priority   = 110
listener_rule_path_patterns = ["/carbon*", "/carbon/*"]
```

Until the load-balancer module is wired, environments keep `create_listener_rule = false`. This still demonstrates the target group and ECS service attachment pattern for review, but a real manual apply should wait until an ALB/listener is present and the target group is reachable.

## Health checks

Two health-check layers are modeled:

- target group HTTP health check through `health_check_path`, matcher, interval, timeout, and thresholds
- ECS container health check command; when no command is supplied, the module builds a demo `curl` command from the container port and health path

Real images should verify that the health endpoint and health-check tooling exist before provisioning.

## Autoscaling

When `enable_autoscaling = true`, the module creates:

- `aws_appautoscaling_target` for ECS desired count
- CPU target-tracking policy
- memory target-tracking policy

Dev examples keep ranges small. Prod examples show a wider production-intent range. Real production services should review minimum capacity, maximum capacity, cooldowns, and alarm/paging integration.

## Cost notes

Provisioning this module can create ongoing cost through:

- Fargate vCPU and memory while tasks run
- ALB target group usage when connected to a load balancer
- CloudWatch log ingestion and retention
- autoscaling policy/metric usage
- NAT gateway, VPC endpoints, or data transfer needed for private image pulls, logs, and secret references

No exact prices are claimed here. Costs change and any manual provisioning is user-owned.

## Production hardening gaps

Before real use, review at least:

- HTTPS-only ALB listeners and certificate management
- WAF or trusted ingress controls at the public edge
- per-service task roles rather than shared application task roles
- exact secret ARN scoping and rotation ownership
- VPC endpoints or NAT egress for image pulls, logs, ECS APIs, and secret references
- container image provenance and vulnerability scanning
- deployment alarms, paging, and rollback workflows
- whether read-only root filesystem works for the specific image
- log retention, retention legal requirements, and data minimisation

## Required inputs

The important dependency inputs are:

- `cluster_arn` and `cluster_name`
- `vpc_id`
- `private_subnet_ids`
- `security_group_ids`
- `task_execution_role_arn`
- `task_role_arn`
- `container_image`

See `variables.tf` for the full typed interface.

## Outputs

The module outputs service, task definition, log group, target group, listener rule, autoscaling, and review-summary values. Outputs never include secret values.
