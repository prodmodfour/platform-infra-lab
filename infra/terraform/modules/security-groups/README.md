# Security groups module

This module models the network traffic boundaries for the public-safe AWS container platform lab. It creates security groups for the public load balancer edge, private ECS services, private PostgreSQL/RDS, and optional private Redis/ElastiCache.

## Resources

- `aws_security_group.load_balancer` — public ALB edge security group.
- `aws_security_group.ecs_service` — private ECS service security group.
- `aws_security_group.rds_postgres` — private PostgreSQL security group.
- `aws_security_group.redis_cache` — optional private cache security group when `enable_redis = true`.
- Standalone `aws_vpc_security_group_ingress_rule` and `aws_vpc_security_group_egress_rule` resources for explicit, reviewable traffic paths.

## Traffic boundaries

The intended traffic matrix is deliberately narrow:

| Source | Destination | Port | Intent |
| --- | --- | --- | --- |
| Public IPv4 CIDRs from `alb_ingress_cidrs` | ALB security group | `alb_ingress_ports` (default `80`) | Internet reaches the public edge only. |
| ALB security group | ECS service security group | `service_port` (default `8080`) | Load balancer forwards health checks and service traffic to tasks. |
| ECS service security group | RDS PostgreSQL security group | `database_port` (default `5432`) | Services can reach the private database. |
| ECS service security group | Redis cache security group | `redis_port` (default `6379`) | Services can reach the private cache only when enabled. |

The module does **not** create public ingress rules for PostgreSQL or Redis. Database and cache security groups only accept traffic from the ECS service security group.

## Inputs

Key inputs:

- `name_prefix` — public-safe prefix for resource names.
- `environment` — environment label for tags.
- `vpc_id` — VPC ID from the network module.
- `alb_ingress_cidrs` — public edge CIDRs; defaults to `0.0.0.0/0` for the demo ALB boundary only.
- `alb_ingress_ports` — public ALB ports; defaults to `[80]`.
- `service_port` — application port used by the ALB-to-ECS rule.
- `database_port` — PostgreSQL port.
- `enable_redis` and `redis_port` — optional cache boundary.
- `common_tags` — public-safe tags merged into resources.

## Outputs

- `load_balancer_security_group_id`
- `ecs_service_security_group_id`
- `rds_postgres_security_group_id`
- `redis_cache_security_group_id` (`null` when Redis is disabled)
- `security_group_ids`
- `rule_summary`

## Security notes

- Public internet ingress is limited to the ALB security group.
- ECS services do not accept direct public ingress.
- PostgreSQL and Redis do not accept public ingress.
- Rules use security group references for private service-to-data flows rather than broad CIDR ranges.
- The ECS service egress model is intentionally strict: only database and optional cache egress are modeled here. Real workloads that need ECR, CloudWatch Logs, third-party APIs, or AWS service access should add reviewed VPC endpoints, NAT egress, or narrowly scoped egress rules in a future change.

## Cost notes

Security groups do not have standalone hourly cost, but the resources that consume them can. ECS tasks and CloudWatch logs are now modeled by the ECS service module; public ALB traffic, RDS instances, Redis nodes, and NAT gateways are additional cost drivers as later modules are added or wired. Any optional manual provisioning remains user-owned and can incur cloud cost.

## Production hardening gaps

Before real production use, review:

- HTTPS-only public ingress and certificate management.
- IPv6 ingress/egress requirements.
- Whether ALB ingress should be restricted by WAF, managed prefix lists, or trusted CIDRs.
- Per-service security groups if services need different ports or data-store access.
- VPC endpoints and egress controls for ECR, CloudWatch Logs, Secrets Manager, SSM Parameter Store, and other AWS APIs.
- Flow logs and threat-detection tooling.

## Validation

Run from the repository root:

```bash
bash scripts/quality-gate.sh
```

Terraform validation uses `terraform init -backend=false` and does not require a real backend or cloud mutation.
