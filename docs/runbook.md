# Runbook

Placeholder for operational runbooks. Step-by-step incident procedures are added in a later runbook ticket.

## Current observability hooks

Use these Terraform-modeled hooks when developing future runbooks:

- ECS service logs follow `/aws/ecs/<name_prefix>/<service-name>`.
- The CloudWatch dashboard output is `cloudwatch_dashboard_name`.
- Alarm summaries are exposed through `cloudwatch_alarm_names` and `cloudwatch_alarm_summary`.
- ALB alarms cover load-balancer 5xx responses and unhealthy targets.
- ECS alarms cover CPU and memory utilization per service.
- RDS alarms cover CPU utilization and low free storage.

Alarm actions are empty in committed examples, so a real user-owned environment must connect alarms to reviewed paging or incident-routing targets outside this repo.

Future runbooks will provide step-by-step public-safe response guidance for common service, database, cache, load-balancer, observability, deployment, and cost-control scenarios.
