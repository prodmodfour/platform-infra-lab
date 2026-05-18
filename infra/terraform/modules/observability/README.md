# Observability module

This module models the CloudWatch observability layer for the public-safe AWS container platform lab.

It creates dashboards and alarms only. It does not create paging integrations, incident-management routes, SNS topics, or secret values. Alarm action lists default to empty so committed examples stay public-safe and validation-only.

## What it creates

- One CloudWatch dashboard per environment.
- ALB alarm for load-balancer-generated 5xx responses.
- Per-service ALB target-group alarms for unhealthy targets.
- Per-service ECS alarms for average CPU and memory utilization.
- RDS PostgreSQL alarms for high CPU and low free storage.
- Dashboard metric widgets for ALB, target health, ECS services, and RDS PostgreSQL.
- Dashboard log widgets for each ECS service log group.
- Outputs that summarize dashboard names, alarm names/ARNs, thresholds, and log group naming conventions.

The ECS service module owns the actual ECS container log groups. This module consumes those log group names to make the dashboard and output conventions reviewable.

## Logs

ECS service logs follow this convention:

```text
/aws/ecs/<name_prefix>/<service-name>
```

For example, a dev service log group is shaped like:

```text
/aws/ecs/platform-infra-lab-dev/carbon-platform-api
```

Dashboard log widgets use CloudWatch Logs Insights queries against each service log group. The module does not inspect, export, or store log contents. Real production use should define retention, data minimisation, sensitive-log handling, and access controls for log readers.

RDS PostgreSQL log exports are configured by the `rds-postgres` module. AWS-managed RDS log groups are not created here, but the dashboard includes RDS service metrics so reviewers can connect database health to service symptoms.

## Metrics

The dashboard covers the main platform signals modeled so far:

- `AWS/ApplicationELB` — ALB 5xx count and target response time.
- `AWS/ApplicationELB` — unhealthy target count per ECS service target group.
- `AWS/ECS` — CPU and memory utilization per service.
- `AWS/RDS` — PostgreSQL CPU, free storage, and connection count.

Application-level business metrics, distributed tracing, SLO burn-rate metrics, and Redis/cache metrics are intentionally left for later hardening. This ticket focuses on the shared CloudWatch primitives required by the current Terraform architecture.

## Alarms

The module creates threshold alarms for:

- ALB 5xx responses.
- unhealthy targets for each ECS service target group.
- ECS CPU utilization for each service.
- ECS memory utilization for each service.
- RDS CPU utilization.
- RDS free storage.

All alarm action lists default to empty:

```hcl
alarm_actions             = []
ok_actions                = []
insufficient_data_actions = []
```

This is deliberate. A public portfolio repo should not commit real SNS topic ARNs, incident-routing webhooks, account IDs, or paging policies. A user-owned environment can pass reviewed action ARNs through untracked local variable files or a secure pipeline.

## Dashboard

The dashboard is named `<name_prefix>-observability` unless `dashboard_name` is supplied. It includes:

- ALB errors and latency.
- target health by service.
- ECS CPU and memory across all configured services.
- RDS PostgreSQL health.
- one recent-log widget per ECS service.
- a text widget documenting the log naming convention and action-routing gap.

CloudWatch dashboards can create ongoing cost when provisioned depending on AWS pricing and usage. Costs change, so this repo does not claim exact prices.

## Public-safety posture

The module accepts references and names only:

- load balancer ARN suffix
- ECS cluster name
- ECS service names
- target group ARN suffixes
- log group names
- RDS instance identifier
- optional alarm action ARNs

It does not require secrets, credentials, Terraform state, real account IDs, backend bucket names, or private endpoints. Committed environment examples keep alarm action lists empty.

## Production gaps

Before real production use, review at least:

- paging and incident-routing ownership
- SNS topic or incident-management ARNs outside this repo
- alarm thresholds against real baseline traffic
- multi-window or burn-rate alarms for customer-facing SLOs
- target 5xx/error-rate alarms, latency percentiles, and request-volume context
- Redis/ElastiCache metrics and alarms if cache availability is user-visible
- application custom metrics and structured logging
- trace correlation and dashboard links
- log retention, access control, encryption, and sensitive-data redaction
- runbook links in alarm descriptions
- alarm suppression strategy during planned maintenance

## Required inputs

Important dependency inputs are:

- `load_balancer_arn_suffix`
- `ecs_cluster_name`
- `ecs_services`
- `rds_instance_identifier`
- threshold variables for ALB, ECS, and RDS alarms
- optional alarm action lists

See `variables.tf` for the full typed interface.

## Outputs

Key outputs include:

- `dashboard_name`
- `dashboard_arn`
- `alarm_names`
- `alarm_arns`
- `dashboard_summary`
- `alarm_summary`
- `log_group_naming_convention`
