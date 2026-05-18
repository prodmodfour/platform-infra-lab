# Load balancer module

This module models the public Application Load Balancer edge for the AWS container platform lab.

It creates the ALB and listener resources only. The `ecs-service` module owns service-specific target groups and listener rules, which keeps edge infrastructure separate from per-service deployment wiring.

## What it creates

- Internet-facing Application Load Balancer by default
- Required HTTP listener with a fixed-response default action for unmatched routes
- Optional HTTPS listener controlled by variables
- Optional ALB access log configuration that references an existing user-owned S3 bucket
- Outputs for DNS, zone ID, listener ARNs, and service target-group wiring

No certificate ARN, access log bucket, DNS zone, or domain name is hard-coded in this public repo.

## Target group wiring pattern

The module exposes `http_listener_arn` and, when enabled, `https_listener_arn`. Environment roots pass the HTTP listener ARN to the ECS service module:

```hcl
listener_arn = module.load_balancer.http_listener_arn
```

Each ECS service module instance then creates:

- one service target group with `target_type = "ip"` for Fargate tasks
- one listener rule with path patterns such as `/carbon*` or `/jobs*`
- a forward action from the listener rule to the service target group

The load balancer listener default action returns a fixed response for unmatched paths. This makes route ownership explicit and avoids accidentally sending all traffic to one service.

## Health checks

The ALB itself uses service target groups for health decisions. Target-group health-check settings live in the ECS service module because each backend can expose a different path, for example `/health`, `/healthz`, or `/ready`.

Operators reviewing a plan should check:

- the listener rule path patterns for each service
- target-group health-check paths and matchers
- ECS container health checks for the same service
- security group rules from the ALB to private ECS tasks

## Public edge and private services

The ALB is the public edge. Its security group is the only internet-facing ingress boundary modeled by this lab. ECS services run in private subnets and accept traffic only from the ALB security group on the configured service port.

PostgreSQL/RDS and Redis/ElastiCache remain private. They are not attached to this ALB and do not receive public ingress rules.

## HTTPS production requirement

The module includes optional HTTPS listener variables, but committed examples keep HTTPS disabled because this public repo must not contain real ACM certificate ARNs or domain ownership details.

Before real production use, enable and review:

- an ACM certificate in a user-owned account
- HTTP-to-HTTPS redirect strategy or HTTPS-only routing
- security group ingress for TCP/443
- TLS policy selection
- DNS alias records
- WAF or trusted-ingress controls where appropriate

## Access logs

Access logs are optional and disabled by default. Enabling them requires an existing user-owned S3 bucket with the correct ALB log-delivery policy. This repo does not create or name a real log bucket.

Access logs can be useful for incident review and traffic analysis, but they can also create storage and request costs. Retention, encryption, lifecycle rules, and data minimisation should be reviewed before enabling them.

## Cost notes

Provisioning this module can create ongoing cost through:

- the Application Load Balancer running continuously
- load balancer capacity and processed traffic
- data transfer through the public edge
- optional access log storage and requests
- downstream ECS/Fargate capacity reached through listener rules

No exact prices are claimed here. Costs change, and any manual provisioning is user-owned.

## Production hardening gaps

Before real use, review at least:

- HTTPS-only posture and certificate rotation
- WAF, bot controls, or trusted ingress restrictions
- access log bucket policy, encryption, retention, and lifecycle
- DNS and health-check behavior during deployments
- listener rule priority collisions as services grow
- deletion protection and cleanup workflow
- ALB and target group alarms in the observability layer

## Required inputs

Important dependency inputs are:

- `public_subnet_ids`
- `security_group_ids`
- `name_prefix`
- `environment`
- `common_tags`

See `variables.tf` for the full typed interface.

## Outputs

Key outputs include:

- `load_balancer_dns_name`
- `load_balancer_zone_id`
- `load_balancer_arn_suffix` for CloudWatch ApplicationELB metrics
- `http_listener_arn`
- `https_listener_arn`
- `listener_summary`
- `target_group_wiring_pattern`
