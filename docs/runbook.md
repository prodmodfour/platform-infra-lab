# Operational runbook

This runbook provides step-by-step, public-safe response procedures for the AWS ECS/Fargate platform pattern in this repository. It assumes any real AWS environment is user-owned and manually operated outside this repo.

This repository does not provide incident automation, deployment automation, rollback automation, real credentials, private values, or secret values. Keep CI and scripts validation-only.

Related references:

- [Operations guide](operations.md)
- [Rollback guide](rollback.md)
- [Deployment guide](deployment.md)
- [Architecture](architecture.md)
- [Service examples](service-examples.md)

## How to use this runbook

For every incident, capture the following in a user-owned incident note, not in this public repo if it contains private data:

- environment: `dev`, `prod`, or a user-owned equivalent
- affected service: `carbon-platform-api`, `job-runner-platform`, `multi-tenant-saas-api`, or shared platform component
- affected route or dependency
- user-visible symptom
- start time and detection source
- most recent deployment/configuration/migration change
- current mitigation decision
- owner and next update time

Public-safety rules during response:

- Do not commit real `.tfvars`, state, plan files, credentials, SSH keys, kubeconfigs, or incident logs with sensitive data.
- Do not paste secret values, private connection strings, private hostnames, tenant data, or real account details into this repo.
- Do not add cloud mutation commands to scripts, CI, package scripts, or build tooling.
- Use read-only checks first. Any real remediation that changes AWS resources is manual, reviewed, user-owned, and may incur cost.

## Universal incident triage

Use this checklist before choosing a component-specific runbook.

1. **Confirm impact.** Which service, route, environment, and users are affected?
2. **Check recent changes.** Was there a service image update, Terraform change, secret rotation, migration, or cache change?
3. **Check alarms.** Review ALB 5xx, unhealthy targets, ECS CPU/memory, RDS CPU, and RDS free storage alarms.
4. **Check health checks.** Confirm ECS desired/running count and ALB target-group health for the affected service.
5. **Check logs.** Review the relevant `/aws/ecs/<name-prefix>/<service-name>` log group.
6. **Check dependencies.** Review RDS connectivity/capacity, Redis status if enabled, and secret-reference resolution.
7. **Choose mitigation.** If a rollout caused the incident, use the [rollback guide](rollback.md). If a dependency is unhealthy, use the relevant runbook below.
8. **Verify recovery.** Confirm metrics, logs, health checks, and alarms stabilize.
9. **Record follow-up.** Capture root-cause hypothesis, action items, and any data-risk decision in a user-owned system.

Optional read-only checks, using user-owned credentials and placeholder resource names only:

```bash
aws ecs describe-services --cluster <cluster-name> --services <service-name>
aws ecs list-tasks --cluster <cluster-name> --service-name <service-name>
aws elbv2 describe-target-health --target-group-arn <target-group-arn>
aws cloudwatch describe-alarms --alarm-names <alarm-name>
aws rds describe-db-instances --db-instance-identifier <db-instance-id>
```

Do not store command output containing private data in this repository.

## Health checks

Use this when an alarm, deployment, or manual check suggests a service is unhealthy.

Expected service health paths:

| Service | Health path | Route examples |
| --- | --- | --- |
| `carbon-platform-api` | `/health` | `/carbon*`, `/carbon/*` |
| `job-runner-platform` | `/healthz` | `/jobs*`, `/jobs/*` |
| `multi-tenant-saas-api` | `/ready` | `/saas*`, `/saas/*` |

Procedure:

1. Identify the target group for the affected service.
2. Check whether targets are `healthy`, `initial`, `draining`, or `unhealthy`.
3. Check ECS service desired/running task count.
4. Check the active deployment and task definition revision.
5. Check application logs for health endpoint failures.
6. Compare the health-check path, container port, matcher, interval, timeout, and startup grace period with the last known-good configuration.
7. If health checks broke after a rollout, use the rollback guide rather than widening security groups or disabling checks.

Success criteria:

- ECS reaches steady state.
- ALB target group reports healthy targets.
- Health endpoint logs are clean and do not expose sensitive data.

## Logs

Use this when symptoms are unclear or when ECS/ALB signals indicate application failure.

Procedure:

1. Open the service log group using the convention `/aws/ecs/<name-prefix>/<service-name>`.
2. Filter by the incident window and the affected task or deployment revision if available.
3. Search for startup errors, health endpoint failures, dependency timeouts, authentication errors, secret-reference failures, and OOM or signal exits.
4. Check whether errors correlate with a specific image tag/digest or config change.
5. Redact sensitive data before sharing excerpts in user-owned incident channels.
6. If logs contain secret values or sensitive tenant data, treat that as a security follow-up and reduce log exposure.

Useful questions:

- Did the service ever start listening on the expected port?
- Did the container fail before the health endpoint was available?
- Are errors dependency-specific, route-specific, or global?
- Did log volume spike enough to create noise or cost concerns?

## Metrics

Use this to identify whether impact is at the ALB, service, database, or cache layer.

Procedure:

1. Open the dashboard named by `cloudwatch_dashboard_name`.
2. Review ALB 5xx and target response time for the incident window.
3. Review unhealthy target count by service.
4. Review ECS CPU and memory for the affected service.
5. Review RDS CPU, free storage, and connections.
6. If Redis is enabled, review cache status, failover events, connection errors, evictions, and whether application logs show cache fallback.
7. Compare the incident window with the most recent deployment or configuration change.

Interpretation guide:

| Pattern | Likely area |
| --- | --- |
| ALB 5xx high and all targets unhealthy | ECS deployment, health check, subnet/security-group path, or shared dependency. |
| ALB latency high but health checks pass | Application slowness, RDS saturation, Redis outage, downstream retry loop, or capacity issue. |
| ECS memory high then tasks stop | Memory leak, undersized task, or workload spike. |
| RDS CPU/connections high with app timeouts | Query/migration issue, pool pressure, traffic spike, or database undersizing. |
| Redis errors plus RDS load spike | Cache outage causing database fallback load. |

## Alarms

Use this when CloudWatch alarms fire or enter insufficient data.

Procedure:

1. Identify alarm name, metric, threshold, evaluation period, and affected dimension.
2. Confirm whether the alarm maps to ALB, ECS, or RDS.
3. Check whether the alarm is expected during a planned maintenance or deployment window.
4. Inspect the dashboard and service logs for the same time period.
5. Choose the component-specific runbook below.
6. After recovery, decide whether the threshold, evaluation period, missing-data behavior, or paging route needs adjustment in user-owned configuration.

Committed examples intentionally keep alarm action lists empty. A real environment should connect alarms to reviewed user-owned paging or incident-routing targets outside this repo.

## RDS connectivity issue

Use this when services cannot reach PostgreSQL or database-backed health checks fail.

Symptoms:

- Application logs show PostgreSQL connection timeouts, authentication failures, DNS failures, TLS errors, or pool exhaustion.
- `carbon-platform-api` or `multi-tenant-saas-api` target health fails after database-dependent startup.
- RDS status, security group, or secret-reference changes occurred recently.

Procedure:

1. Confirm the affected service uses the expected `DATABASE_URL` secret reference name/ARN.
2. Check ECS stopped-task reasons for secret resolution or IAM failures.
3. Confirm the RDS instance status is available or identify maintenance/failover status.
4. Confirm RDS remains private and is not publicly accessible.
5. Confirm the ECS service security group is allowed to reach the RDS security group on the PostgreSQL port.
6. Confirm tasks are in private subnets that can resolve and reach the RDS endpoint.
7. Check RDS CPU, connections, free storage, and logs for saturation symptoms.
8. If a credential value changed, repair or restore it outside this repo through the user-owned secret process.
9. If a recent infrastructure change broke connectivity, revert the smallest unsafe change through the reviewed manual workflow.

Escalate to database owner or user-owned cloud operator if:

- data integrity is uncertain
- restore or point-in-time recovery is being considered
- storage is exhausted
- production credentials may be compromised

Success criteria:

- ECS tasks connect successfully.
- Health checks pass for database-backed services.
- RDS remains private and secret values remain outside the repository.

## Service crash loop

Use this when ECS tasks repeatedly stop or fail to become healthy.

Symptoms:

- ECS service events show repeated task starts/stops.
- Desired count is greater than running count for an extended period.
- Logs show startup exceptions, missing config, failed image startup, or OOM.

Procedure:

1. Identify the last healthy task definition revision.
2. Compare image, CPU/memory, environment variables, secret references, health path, and container command between revisions.
3. Check stopped-task reason and container exit code.
4. Review logs from the first failed task in the new deployment.
5. If the image is bad, roll back to the previous known-good image using the rollback guide.
6. If a required non-secret environment variable is missing, restore the last known-good value shape.
7. If a secret reference fails, fix the external secret value/reference or IAM permission without exposing values.
8. If OOM is suspected, review memory utilization and application behavior before changing sizing.

Success criteria:

- Running task count matches desired count.
- The deployment reaches steady state.
- ALB target group reports healthy targets.
- Logs no longer show repeated startup failures.

## High 5xx rate

Use this when the ALB 5xx alarm fires or users report server errors.

Symptoms:

- ALB `HTTPCode_ELB_5XX_Count` rises.
- One path family, such as `/carbon*`, `/jobs*`, or `/saas*`, returns errors.
- All service paths fail at once.

Procedure:

1. Determine whether the errors are isolated to one route or shared across all routes.
2. Check target health for the affected service target groups.
3. Check ECS deployment events and service logs.
4. Check listener rule priorities and path patterns for accidental route changes.
5. Check RDS and Redis if logs show dependency errors.
6. If the spike follows a deployment, stop promotion and use the rollback guide.
7. If all services fail and targets are unhealthy, check shared security groups, private subnets, ALB configuration, and secret-reference failures.
8. If only one service fails, mitigate that service first and avoid broad platform changes.

Success criteria:

- 5xx rate returns to expected levels.
- Target groups are healthy.
- Application logs no longer show repeated request failures.

## High latency

Use this when response time rises but services may still pass health checks.

Symptoms:

- ALB target response time rises.
- Users report slow requests.
- ECS CPU/memory, RDS connections, or Redis errors increase.

Procedure:

1. Identify affected route and service.
2. Compare latency with ECS CPU and memory.
3. Check desired/running tasks and autoscaling bounds.
4. Check RDS CPU, connections, locks, free storage, and recent migrations.
5. Check Redis status if the service depends on cache.
6. Check logs for retries, downstream timeouts, slow queries, or queue backlog.
7. If a release caused latency and data compatibility is safe, use the rollback guide.
8. If database or cache saturation caused latency, use the relevant dependency runbook.
9. If capacity is the cause, use a reviewed user-owned scaling or throttling process.

Success criteria:

- Target response time returns to baseline or accepted incident threshold.
- ECS and RDS metrics stabilize.
- Logs show fewer retry/timeout paths.

## Database saturation

Use this when RDS metrics or application logs indicate database pressure.

Symptoms:

- RDS CPU is high.
- Free storage is low.
- Connection count is high or connections are refused.
- Logs show slow queries, lock waits, migration failures, or write errors.

Procedure:

1. Confirm whether a migration, batch job, traffic spike, or cache outage started recently.
2. Check RDS CPU, free storage, connections, maintenance events, and logs.
3. Check service desired counts and connection pool behavior.
4. If a migration is running, determine whether it is safe to continue, pause, or roll forward.
5. If storage is low, preserve backups/snapshots and use the reviewed manual change process for storage decisions.
6. If connections are exhausted, reduce connection pressure before adding more tasks.
7. If data restore or point-in-time recovery is considered, escalate and document data-loss/downtime trade-offs in user-owned notes.

Success criteria:

- RDS CPU, storage, and connections return to safe levels.
- Database-backed services regain healthy targets.
- No public access or secret exposure was introduced.

## Redis unavailable

Use this when cache access fails or Redis-related application errors appear.

Symptoms:

- Logs show Redis connection refused, timeout, TLS, or command errors.
- Redis endpoint or replication group is unavailable.
- Application latency rises because cache fallback increases database load.

Procedure:

1. Confirm Redis is expected to be enabled for the environment.
2. Determine which service depends on Redis and whether cache is authoritative or disposable.
3. Check ECS-to-Redis security group and private subnet path.
4. Check cache endpoint references and any user-owned secret references for cache connection strings.
5. Review Redis failover, node health, and snapshot/maintenance events.
6. If cache is optional, use user-owned config to degrade gracefully or bypass cache.
7. If stale cache data is causing incorrect behavior, use a user-owned invalidation process outside this repo.
8. If a recent Terraform input change caused the issue, revert the smallest reviewed cache change.

Success criteria:

- Cache-dependent errors stop or are safely bypassed.
- Redis reports healthy where enabled.
- RDS load does not remain elevated because of cache loss.
- Redis remains private and no cache credentials are committed.

## Deployment stuck

Use this when an ECS deployment does not reach steady state.

Symptoms:

- Deployment remains in progress for longer than expected.
- Deployment circuit breaker rolls back.
- Tasks keep failing target-group health checks.
- Desired count and running count do not match.

Procedure:

1. Identify the active deployment and task definition revision.
2. Check ECS service events for image pull, IAM, secret, subnet, capacity, or health-check errors.
3. Check target health for new tasks.
4. Check logs from newly launched tasks.
5. Compare image reference, health path, container port, listener rule, environment variables, and secret references with the last stable release.
6. If the deployment is automatically rolling back, let it settle before introducing another change.
7. If the new revision is unsafe, restore the previous known-good image/config through the manual rollout path.
8. Pause unrelated changes until the service is stable.

Success criteria:

- Only one active deployment remains.
- Desired and running task counts match.
- Target health is healthy.
- Alarms return to normal or understood states.

## Cost cleanup

Use this after any optional user-owned lab deployment, test, incident, or rollback.

Procedure:

1. List resources created for the environment using user-owned tooling or the Terraform state stored outside this repo.
2. Confirm whether ECS services/tasks, ALB, NAT gateway, RDS, Redis, CloudWatch dashboards, log groups, snapshots, ALB access logs, Elastic IPs, and backend state resources still exist.
3. Decide which resources must remain for investigation, audit, backup, or future testing.
4. Remove unneeded resources through a reviewed user-owned cleanup process outside this repository.
5. Check retained snapshots, final snapshots, log retention, and access-log buckets.
6. Delete generated plans and private value files from local machines or secure temporary locations when no longer needed.
7. Keep state files and backend settings outside this repo.
8. Record intentional retained resources and owners in user-owned notes.

Success criteria:

- No unexpected long-running lab resources remain.
- Retained backups/snapshots/logs are intentional.
- The public repo still contains no state, plans, secrets, credentials, or private values.

## Access review

Use this after incidents, before production-like use, and on a regular cadence for long-lived environments.

Procedure:

1. Review human AWS access and prefer user-owned SSO or short-lived roles.
2. Confirm GitHub Actions has no deployment credentials and remains validation-only.
3. Review Terraform backend access for state readers/writers.
4. Review ECS task execution role permissions for image pull, log write, and secret-reference resolution only.
5. Review ECS task role permissions separately for application runtime needs.
6. Review who can read Secrets Manager values, CloudWatch logs, RDS credentials, and Terraform state.
7. Remove stale IAM permissions, unused secret references, and departed operator access.
8. Rotate user-owned secrets if access was broader than intended or if incident logs suggest exposure.
9. Confirm RDS and Redis remain private and are not reachable from public networks.

Success criteria:

- Access is least-privilege and justified.
- Secret values and state access are limited to required operators/systems.
- CI cannot mutate cloud infrastructure.
- Any follow-up hardening tasks are tracked outside this public repo if they contain private details.

## Closeout checklist

Before closing an incident or operational task:

- [ ] User impact is resolved or accepted.
- [ ] Health checks are green for affected services.
- [ ] ALB 5xx, latency, ECS CPU/memory, and dependency metrics are stable.
- [ ] Relevant alarms are OK or intentionally suppressed in user-owned operations.
- [ ] Logs no longer show repeated startup, health-check, secret, database, or cache errors.
- [ ] RDS and Redis remain private.
- [ ] No secrets, private values, state files, plans, or sensitive logs were committed.
- [ ] Rollback or forward-fix decision is documented in user-owned notes.
- [ ] Cost cleanup and access review were considered.
