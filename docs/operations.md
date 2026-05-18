# Operations guide

This guide describes how to operate the AWS ECS/Fargate platform pattern modeled in this repository. It is public-safe operational documentation for a portfolio lab: it does not add deployment automation, rollback automation, real account details, private hostnames, credentials, or secret values.

Any real operation against AWS is optional, manual, user-owned, and can incur cost. Scripts and CI in this repository remain validation-only.

Related references:

- [Architecture](architecture.md)
- [Deployment guide](deployment.md)
- [Rollback guide](rollback.md)
- [Runbook](runbook.md)
- [Service examples](service-examples.md)
- [Secret reference pattern](secrets.md)

## Operational scope and safety posture

This repo models the infrastructure primitives an operator would use after a manual, user-owned deployment:

- public Application Load Balancer listener and ECS target groups
- private ECS/Fargate services for `carbon-platform-api`, `job-runner-platform`, and `multi-tenant-saas-api`
- per-service CloudWatch log groups
- CloudWatch dashboard and alarms for ALB, ECS, and RDS signals
- private RDS PostgreSQL database placement
- optional private Redis/ElastiCache cache placement
- metadata-only Secrets Manager references for ECS secret injection
- IAM separation between task execution and application task roles
- public-safe Terraform outputs that expose names and references, not secret values

Operational rules:

- Do not commit incident artifacts containing secrets, private hostnames, customer data, Terraform state, generated plans, real `.tfvars`, credentials, SSH keys, kubeconfigs, or sensitive logs.
- Do not add scripts or CI jobs that run cloud mutations. Real operational actions stay manual and user-owned.
- Treat the committed fake images as examples only. A real deployment needs real images and real secret values managed outside this repo.
- Keep alarm actions public-safe in committed examples. Real paging targets belong in user-owned configuration outside this repository.

## Platform operating model

| Area | Modeled resource | Operator focus |
| --- | --- | --- |
| Public edge | Application Load Balancer, HTTP listener, optional HTTPS variables | Route health, 5xx rate, latency, listener rules, TLS/DNS hardening outside this lab. |
| Service runtime | ECS/Fargate services in private subnets | Desired/running tasks, deployment state, crash loops, CPU/memory, target health. |
| Logs | `/aws/ecs/<name-prefix>/<service-name>` log groups | Startup errors, health endpoint behavior, dependency failures, sensitive-log avoidance. |
| Metrics | CloudWatch dashboard widgets and alarms | ALB errors/latency, unhealthy targets, ECS CPU/memory, RDS CPU/free storage. |
| Database | Private RDS PostgreSQL | Connectivity, connections, CPU, storage, backups, migration safety. |
| Cache | Optional private Redis/ElastiCache | Availability, failover, connection errors, whether cache is disposable. |
| Secrets | Secrets Manager references only | Reference resolution, IAM permissions, rotation outside the repo, no value exposure. |
| Access | IAM task roles, execution roles, human/operator access outside repo | Least-privilege review, temporary access, log/secret/backend access review. |

## Health checks

Health checks are the first operational signal for this platform.

| Service | Example route patterns | Expected health path | Notes |
| --- | --- | --- | --- |
| `carbon-platform-api` | `/carbon*`, `/carbon/*` | `/health` | Database-backed API; treat migration or database connectivity changes as release risks. |
| `job-runner-platform` | `/jobs*`, `/jobs/*` | `/healthz` | Worker-style service; health should not hide stuck queues or failed dependencies. |
| `multi-tenant-saas-api` | `/saas*`, `/saas/*` | `/ready` | Readiness should reflect required dependencies without logging sensitive tenant data. |

Routine health review:

1. Confirm the ECS service has the expected desired and running task counts.
2. Confirm the active ECS deployment reaches steady state.
3. Confirm ALB target groups report healthy targets for the expected health path.
4. Confirm the ALB listener routes only the intended paths to each target group.
5. Confirm container logs show healthy startup and no repeated health endpoint failures.
6. Confirm dependency checks are meaningful: do not mark a service healthy if required database, cache, or secret references are broken.
7. If a health check regressed after a rollout, stop promotion and use the [rollback guide](rollback.md).

Health-check design notes:

- ALB health checks verify the load-balanced path from ALB to private ECS tasks.
- ECS container health checks verify the process inside the task remains responsive.
- Database and cache health should be visible through application logs, metrics, and safe internal checks rather than public database/cache exposure.
- Health endpoints must not return secret values, private connection strings, tenant data, or verbose stack traces.

## Logs

The ECS service module creates per-service CloudWatch log groups with this convention:

```text
/aws/ecs/<name-prefix>/<service-name>
```

Example public-safe names:

- `/aws/ecs/platform-infra-lab-dev/carbon-platform-api`
- `/aws/ecs/platform-infra-lab-dev/job-runner-platform`
- `/aws/ecs/platform-infra-lab-dev/multi-tenant-saas-api`

Use logs to answer:

- Did the container start successfully?
- Did it fail image pull, boot, configuration, or secret-reference resolution?
- Are health endpoints returning expected status codes?
- Are PostgreSQL or Redis connection attempts failing?
- Did latency or error rate increase after a specific task definition revision?
- Are logs accidentally exposing secrets or sensitive tenant/user data?

Log safety expectations:

- Do not paste sensitive log lines into this public repository.
- Redact secret values, tokens, private hostnames, request IDs tied to sensitive systems, and tenant data before sharing outside user-owned incident channels.
- Keep retention settings deliberate. Dev examples use shorter retention; production-intent examples should match compliance and incident-analysis needs.
- ALB access logs are optional and require a user-owned bucket if enabled; do not commit real log bucket names here.

## Metrics

The observability module models a CloudWatch dashboard and alarms. Key Terraform outputs include:

- `cloudwatch_dashboard_name`
- `cloudwatch_alarm_names`
- `cloudwatch_alarm_summary`
- `cloudwatch_log_group_naming_convention`
- `ecs_service_log_group_names`
- `ecs_service_summaries`
- `rds_postgres_monitoring_summary`
- `redis_cache_availability_summary`

Primary operating signals:

| Signal | Watch for | Typical next step |
| --- | --- | --- |
| ALB 5xx count | Load-balancer-generated failures | Check listener rules, target health, security groups, TLS/DNS if used. |
| Target unhealthy count | ECS tasks failing target-group health | Check health path, container port, deployment events, logs, startup time. |
| Target response time | User-visible latency | Check app logs, ECS CPU/memory, database saturation, Redis availability. |
| ECS CPU utilization | Compute saturation or runaway work | Review scaling range, recent traffic, crash loops, job backlog. |
| ECS memory utilization | Memory leak or undersized tasks | Check OOM/stopped-task reasons and recent code/config changes. |
| Desired/running task count | Deployment or capacity issue | Inspect ECS deployment state and task placement failures. |
| RDS CPU utilization | Query load or undersized instance | Review slow queries, migration activity, connection pool behavior. |
| RDS free storage | Storage pressure | Stop writes if needed, review retention, snapshots, table growth, autoscaling. |
| RDS connections | Pool exhaustion or traffic spike | Review app connection pools and task count. |
| Redis status/connection errors | Cache outage or failover | Decide whether the app can safely bypass cache; check private connectivity. |
| CloudWatch log ingestion | Unexpected log volume | Reduce noisy logs and verify no secrets are being emitted. |

The committed dashboard focuses on shared infrastructure metrics. Production use should add application SLOs, business metrics, trace correlation, Redis alarms, and paging routes outside this public lab.

## Alarms

Modeled alarms include:

- ALB 5xx responses
- unhealthy targets per ECS service target group
- ECS CPU utilization per service
- ECS memory utilization per service
- RDS CPU utilization
- RDS low free storage

Alarm action lists are intentionally empty in committed examples. This keeps the repository public-safe and avoids committing real SNS, chat, or incident-routing ARNs.

Alarm response principles:

1. Confirm the alarm scope: environment, service, resource, threshold, and time window.
2. Check whether the alarm correlates with a recent deployment, config change, migration, traffic spike, or AWS event.
3. Inspect the CloudWatch dashboard and the relevant service logs.
4. Decide whether to mitigate, roll back, scale through a reviewed manual process, or continue investigation.
5. Record incident notes in a user-owned system, not in this public repo if they contain private data.
6. After recovery, tune thresholds only after reviewing real baseline behavior.

## Incident triage

Use this triage loop for any platform incident:

1. **Declare scope.** Identify environment, affected service/route, user-visible symptom, start time, and whether the issue follows a recent change.
2. **Protect public safety.** Keep secrets, state, private values, and sensitive logs out of this repository.
3. **Check the public edge.** Review ALB 5xx, latency, listener rules, target health, and route patterns.
4. **Check ECS.** Review service events, active deployments, desired/running task counts, stopped-task reasons, CPU/memory, and task logs.
5. **Check dependencies.** Review RDS connectivity/capacity, Redis availability if enabled, and secret-reference resolution.
6. **Decide action.** If a rollout caused the issue, use the [rollback guide](rollback.md). If capacity or dependency health caused the issue, use the relevant runbook.
7. **Verify recovery.** Confirm target health, error rate, latency, logs, and alarms return to expected levels.
8. **Follow up.** Create user-owned post-incident notes and action items without committing private data.

## RDS connectivity issue

Symptoms:

- ECS tasks cannot connect to PostgreSQL.
- Application logs show connection refused, timeout, authentication, DNS, TLS, or pool exhaustion errors.
- ALB target health fails because required database checks fail.

First checks:

- Confirm RDS remains `publicly_accessible = false` and reachable only from the ECS service security group.
- Confirm the ECS-to-RDS security group rule still allows the PostgreSQL port.
- Confirm private subnet and route table changes did not isolate ECS tasks from the database endpoint.
- Confirm the service has the expected `DATABASE_URL` secret reference and IAM permission path.
- Confirm RDS status, CPU, connections, storage, maintenance events, and recent failover or modification events.

Response:

- If a recent Terraform/security-group change caused the issue, revert the smallest unsafe change through the manual reviewed workflow.
- If credentials or connection strings changed, fix the user-owned secret value or restore the known-good secret reference outside this repo.
- If the database is saturated, follow [Database saturation](#database-saturation) instead of widening network access.
- Do not make RDS public to debug connectivity.

Verification:

- New ECS tasks start without database connection errors.
- ALB targets become healthy for database-dependent services.
- RDS remains private and the security boundary is unchanged.

## Service crash loop

Symptoms:

- ECS repeatedly stops and replaces tasks.
- Desired count and running count do not converge.
- Logs show startup exceptions, missing config, failed migrations, health-check failures, OOM, or dependency errors.

First checks:

- ECS service events and stopped-task reasons.
- Last task definition revision and image tag/digest.
- Container logs for the first failure after startup.
- Secret reference names/ARNs and execution-role permissions.
- CPU/memory task sizing and container health-check command.

Response:

- If the crash started with a new image, roll back to the previous known-good image through the documented manual process.
- If non-secret configuration changed, restore the last known-good value shape.
- If secret resolution failed, repair the external secret value/reference without exposing it in this repo.
- If memory is exhausted, review sizing and application behavior before increasing capacity.
- Do not disable health checks to hide real startup failures.

Verification:

- The ECS deployment reaches steady state.
- Stopped-task reasons no longer repeat.
- Logs show clean startup and health endpoint responses.
- ALB target health and 5xx alarms recover.

## High 5xx rate

Symptoms:

- ALB 5xx alarm fires.
- Users see server errors.
- One route or all routes return failures.

First checks:

- Determine whether errors are ALB-generated or target-generated.
- Check target health per service.
- Check listener rules and path patterns.
- Check ECS logs for exceptions, dependency failures, or secret errors.
- Check RDS and Redis health if errors are dependency-related.

Response:

- If only one service path is affected, focus on that target group and service deployment.
- If all services are affected, check shared ALB, security groups, private subnets, secrets, and database/cache dependencies.
- If the spike follows a deployment, stop promotion and use the [rollback guide](rollback.md).
- If the spike follows a dependency incident, mitigate the dependency before changing application routing.

Verification:

- ALB 5xx returns to expected levels.
- Target groups are healthy.
- Logs no longer show repeated exceptions for the affected request path.

## High latency

Symptoms:

- ALB `TargetResponseTime` increases.
- Health checks may still pass while user requests are slow.
- ECS CPU/memory, RDS connections, or Redis errors may rise.

First checks:

- Break down impact by route/service.
- Compare latency with ECS CPU/memory and running task count.
- Check RDS CPU, connections, locks, storage, and recent migrations.
- Check Redis availability or failover if the service depends on cache.
- Check logs for slow external calls, retries, timeouts, and queue backlog.

Response:

- If traffic exceeds safe capacity, use a reviewed manual scaling or throttling process outside this repo.
- If a database migration or query caused latency, pause rollout and follow database runbooks.
- If Redis is unavailable and the app can bypass cache, use the cache runbook to decide safe degradation.
- If the issue follows a service release, consider rollback after verifying data compatibility.

Verification:

- Target response time returns to baseline or an accepted incident threshold.
- ECS and RDS metrics stabilize.
- Logs show fewer timeout/retry paths.

## Database saturation

Symptoms:

- RDS CPU, connections, storage, or latency alarms fire.
- Application logs show slow queries, connection pool exhaustion, lock waits, or write failures.
- Health checks fail for database-backed services.

First checks:

- RDS CPU, free storage, connections, maintenance events, and log exports.
- Recent migrations, batch jobs, traffic changes, and service desired count changes.
- Application connection pool settings and retry behavior.
- Whether Redis/cache failure shifted unexpected load to the database.

Response:

- Stop or slow the traffic source through user-owned application controls if available.
- Prefer query/migration fixes over exposing the database or broadly increasing privileges.
- If storage is low, preserve backups/snapshots and review storage scaling through the manual change process.
- If connection pools are exhausted, reduce connection pressure and review app pool sizing before scaling tasks up.
- For possible data loss or restore decisions, require explicit user-owned approval and communication.

Verification:

- RDS CPU, storage, and connection metrics return to safe levels.
- Application error rate and latency recover.
- No public database access or secret exposure was introduced.

## Redis unavailable

Symptoms:

- Application logs show Redis connection failures, timeouts, or cache command errors.
- Latency rises because cache reads fall back to PostgreSQL or recomputation.
- Redis replication group status indicates failover or unavailable nodes.

First checks:

- Confirm Redis is expected to be enabled for the environment.
- Confirm ECS-to-Redis security group rules and private subnet placement.
- Confirm the cache endpoint reference matches the enabled environment.
- Determine whether cache data is disposable or authoritative for the application behavior.
- Check whether database saturation is a downstream effect of cache loss.

Response:

- If cache is optional, allow safe degradation or switch to a cache-bypass mode through user-owned application config.
- If stale cache data is causing impact, use a user-owned invalidation process outside this repo.
- If a Terraform cache input caused the outage, revert the smallest reviewed change.
- Do not expose Redis publicly or commit cache auth tokens/connection strings.

Verification:

- Application cache errors stop or are safely bypassed.
- Redis endpoint status is healthy where enabled.
- Database load remains stable after cache recovery.

## Deployment stuck

Symptoms:

- ECS deployment never reaches steady state.
- Desired and running task counts remain mismatched.
- Deployment circuit breaker rolls back or repeatedly replaces tasks.
- Target groups stay unhealthy after a new task definition.

First checks:

- ECS deployment events and stopped-task reasons.
- Image pull permissions and fake-versus-real image references.
- Secret-reference resolution and execution-role permissions.
- Health-check path, target group port, listener rule, and startup grace period.
- Private subnet egress path for image pulls, logs, and AWS APIs in user-owned environments.

Response:

- If circuit breaker rollback is in progress, let it complete before making additional changes.
- If the new image/config is bad, restore the previous known-good task definition or values through the manual rollout process.
- If capacity or networking blocks placement, fix the smallest dependency issue without weakening security boundaries.
- Pause unrelated changes until one service reaches steady state.

Verification:

- One active deployment remains and reports steady state.
- ALB target health is healthy for the expected path.
- Logs show stable startup.

## Cost cleanup

Manual provisioning can create resources that continue billing. This section is an operations checklist only; detailed cost documentation is handled separately.

After any user-owned lab run:

- Confirm whether NAT gateways, ALBs, ECS services/tasks, RDS instances, Redis replication groups, CloudWatch dashboards, logs, snapshots, and final snapshots still exist.
- Stop or remove resources only through a reviewed user-owned cleanup process outside this repository.
- Check for retained RDS snapshots, Redis snapshots, ALB access-log buckets, CloudWatch log groups, Elastic IPs, and state backend resources.
- Reduce or expire log retention where appropriate for a disposable environment.
- Keep Terraform state, backend config, private values, and generated plans outside the repo during cleanup.
- Record what remains intentionally retained and why.

Do not claim exact prices in this repo. AWS prices change and depend on region, usage, and account settings.

## Access review

Review access after deployments, incidents, and periodically for long-lived environments.

Checklist:

- Confirm human access uses user-owned SSO/short-lived roles where possible.
- Confirm GitHub Actions remains validation-only and has no cloud credentials for deployment.
- Confirm Terraform backend access is limited to operators who need state access.
- Confirm RDS, Redis, and secret values are not exposed through public networks or public repos.
- Confirm ECS task execution role permissions are limited to image pull, log write, and required secret-reference resolution.
- Confirm application task role permissions are separate and least-privilege for runtime AWS API needs.
- Confirm CloudWatch log readers are appropriate for the sensitivity of application logs.
- Remove unused secret references, IAM permissions, and stale operator access.
- Rotate user-owned secrets outside this repo if access was over-broad or suspected compromised.

## Production hardening gaps

Before using this pattern for real production traffic, add or review:

- TLS, DNS, WAF, and trusted ingress at the ALB edge
- VPC endpoints or reviewed NAT egress for private tasks
- application SLOs, tracing, and business metrics
- Redis-specific metrics and alarms if cache is user-visible
- paging and incident-routing ownership
- runbook links in alarm descriptions
- database backup restore testing and migration automation
- RDS Proxy or connection-pool strategy where needed
- least-privilege per-service task roles
- structured logging and sensitive-data redaction
- game days for rollback, database restore, cache failover, and access revocation
