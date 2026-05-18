# Operations

Placeholder for full operations guidance. Detailed incident playbooks are added in a later operations ticket.

## Implemented operational primitives

The current Terraform modules create reviewable primitives for day-two operations:

- ALB listener rules and target-group health checks for the three demo services.
- Per-service CloudWatch log groups created by the ECS service module.
- ECS desired-count autoscaling policies for CPU and memory target tracking.
- RDS PostgreSQL private endpoint, resource ID, backup, storage, and monitoring summaries.
- Redis cache enabled/disabled state, private endpoint references, availability, security, snapshot, and connection-reference summaries.
- CloudWatch observability dashboard covering ALB, target health, ECS CPU/memory, RDS health, and recent ECS logs.
- CloudWatch alarms for ALB 5xx responses, unhealthy targets, ECS CPU/memory, RDS CPU, and RDS free storage.

## Alarm routing posture

Committed examples intentionally keep alarm action lists empty. Real paging, SNS topics, chat integrations, or incident-management ARNs must be supplied only from a user-owned environment outside this repo.

Future content will turn these primitives into health checks, log-review steps, metrics, alarm response, incident triage, service crash loop response, high error rate response, load-balancer routing checks, database saturation, cache issues, deployment stalls, access reviews, and cost cleanup.
