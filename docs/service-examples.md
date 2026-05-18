# Service examples

This document describes the three public-safe portfolio service examples wired by the Terraform environments. The examples demonstrate ECS/Fargate deployment patterns only. No application code, real images, real secret values, private hostnames, or real account details are stored in this repository.

Terraform entry points:

- `var.ecs_services` in each environment defines fake image URIs, container ports, health paths, listener path patterns, desired count, CPU/memory, placeholder environment variables, and autoscaling settings.
- `var.ecs_secret_definitions` defines metadata-only Secrets Manager references for ECS task-definition secret injection. Terraform creates secret containers, not secret values.
- `var.service_example_profiles` documents database/cache needs, expected health paths, metrics/logging expectations, and deployment notes for reviewers.
- `output.service_example_catalog` combines the service config and profile metadata into a review-friendly summary.

## Environment differences

| Environment | Service count | Sizing posture | Cache posture | Secret posture |
| --- | --- | --- | --- | --- |
| `dev` | three services, one task each by default | small CPU/memory and narrow autoscaling ranges | Redis disabled by default for cost-aware review | dev-scoped metadata-only secret references |
| `prod` | three services, two tasks each by default | larger CPU/memory and wider autoscaling ranges | Redis enabled to show private cache and failover intent | prod-scoped metadata-only secret references |

Both environments use the same public-safe fake image names under `public.ecr.aws/example/...:demo`.

## `carbon-platform-api`

| Area | Example |
| --- | --- |
| Fake image | `public.ecr.aws/example/carbon-platform-api:demo` |
| Listener paths | `/carbon*`, `/carbon/*` |
| Expected health path | `/healthz` |
| Placeholder environment variables | `APP_ENV`, `SERVICE_NAME`, `LOG_LEVEL`, `DATABASE_MODE` |
| Secret references | `DATABASE_URL` as a Secrets Manager reference only |
| Database/cache needs | Requires private PostgreSQL through a `DATABASE_URL` reference. No Redis/Valkey dependency is modeled in the committed example. |
| Metrics/logging expectations | Review ALB target health, ALB 5xx, ECS CPU, ECS memory, and the `/aws/ecs/<name-prefix>/carbon-platform-api` log group. |
| Deployment notes | Treat database migrations as a separate reviewed operation. Update image references only in user-owned changes after validation passes. |

## `job-runner-platform`

| Area | Example |
| --- | --- |
| Fake image | `public.ecr.aws/example/job-runner-platform:demo` |
| Listener paths | `/jobs*`, `/jobs/*` |
| Expected health path | `/healthz` |
| Placeholder environment variables | `APP_ENV`, `SERVICE_NAME`, `LOG_LEVEL`, `WORKER_MODE`, `QUEUE_NAME` |
| Secret references | `JOB_RUNNER_API_KEY` as a Secrets Manager reference only |
| Database/cache needs | No PostgreSQL dependency is modeled in the committed example. Redis/Valkey can be used by a real design for queue coordination or worker leases; dev keeps cache disabled by default and prod enables it to show the private cache tier. |
| Metrics/logging expectations | Review ECS CPU/memory for worker pressure, ALB target health for the worker health endpoint, and the `/aws/ecs/<name-prefix>/job-runner-platform` log group for lifecycle/retry placeholders. |
| Deployment notes | A real worker rollout should drain or pause job intake before image replacement. Keep real queue credentials outside this repository. |

## `multi-tenant-saas-api`

| Area | Example |
| --- | --- |
| Fake image | `public.ecr.aws/example/multi-tenant-saas-api:demo` |
| Listener paths | `/saas*`, `/saas/*` |
| Expected health path | `/readyz` |
| Placeholder environment variables | `APP_ENV`, `SERVICE_NAME`, `LOG_LEVEL`, `TENANCY_MODE`, `DATABASE_MODE` |
| Secret references | `DATABASE_URL`, `JWT_SIGNING_KEY` as Secrets Manager references only |
| Database/cache needs | Requires private PostgreSQL through a `DATABASE_URL` reference. Redis/Valkey can be used by a real design for sessions, rate limits, or tenant cache entries. |
| Metrics/logging expectations | Review ALB 5xx, target health, latency dashboard widgets, ECS CPU/memory, and the `/aws/ecs/<name-prefix>/multi-tenant-saas-api` log group. Logs should avoid sensitive tenant data. |
| Deployment notes | Coordinate schema migrations and backward-compatible tenant configuration before a real rollout. Rotate signing references outside this repository and verify ECS secret injection before shifting traffic. |

## Public-safety reminders

- Images are fake portfolio placeholders.
- Secret references are names/ARNs only; values are created outside this public repo or by a secure user-owned pipeline.
- Database and cache access stays private through security group boundaries.
- This repo validates Terraform and documents optional manual use, but it does not automate provisioning or rollout.
