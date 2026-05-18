# Rollback guide

This guide describes public-safe rollback strategies for the AWS ECS/Fargate platform pattern modeled in this repository. It is written for review and operator planning only. The repository does not provide rollback scripts, CI-driven deployment, CI-driven rollback, or automated cloud mutation.

Any real rollback is optional, manual, user-owned, and can incur cloud cost. Use user-owned credentials, private values, and approved change-management processes outside this public repository.

Related references:

- [Deployment guide](deployment.md)
- [Architecture](architecture.md)
- [Service examples](service-examples.md)
- [Secret reference pattern](secrets.md)

## Rollback principles

- Prefer the smallest safe rollback that restores user impact without hiding data-loss or security issues.
- Stop promotion immediately when health checks, target health, 5xx, latency, logs, or database/cache signals regress.
- Keep the previous known-good image digest, service configuration, and secret-reference mapping available before any rollout.
- Treat database rollback as a separate data-safety decision, not as a simple ECS redeploy.
- Do not commit real `.tfvars`, generated plan files, Terraform state, credentials, private hostnames, or secret values while investigating.
- Do not add rollback automation to scripts or CI. CI remains validation-only.

## Decision tree

```text
Incident during or after rollout?
|
+-- Is impact isolated to a new container image?
|   +-- Yes: roll ECS service back to the previous known-good image/task definition.
|   +-- No: continue.
|
+-- Are ALB targets unhealthy or ECS deployment unable to reach steady state?
|   +-- Yes: inspect ECS deployment events, task exits, container logs, target health,
|   |       listener rule changes, and health-check path changes; roll back the smallest
|   |       service or routing change that caused the failure.
|   +-- No: continue.
|
+-- Did non-secret environment variables or secret references change?
|   +-- Yes: restore the previous public-safe config shape or user-owned secret reference,
|   |       then redeploy only after validation and secret-resolution checks pass.
|   +-- No: continue.
|
+-- Did a database migration or stateful data change occur?
|   +-- Yes: pause application rollout, protect backups/snapshots, choose forward fix,
|   |       compatibility shim, restore, or point-in-time recovery based on data risk.
|   +-- No: continue.
|
+-- Is RDS, Redis, or ALB infrastructure unhealthy?
    +-- Yes: use the component playbooks below; avoid destructive changes as a first step.
    +-- No: continue normal incident triage with logs, metrics, and recent change review.
```

## Metrics/logs to check

Use these signals before and after every rollback decision:

| Area | Primary signals | Why it matters |
| --- | --- | --- |
| ALB | `HTTPCode_ELB_5XX_Count`, `TargetResponseTime`, target-group `UnHealthyHostCount`, listener rule/path review | Confirms public request impact and routing health. |
| ECS service | deployment events, desired/running task count, stopped-task reasons, `CPUUtilization`, `MemoryUtilization` | Confirms whether the service can launch and stay healthy. |
| Container logs | `/aws/ecs/<name-prefix>/<service-name>` log groups | Confirms image startup, app errors, missing config, dependency failures, and health endpoint behavior. |
| RDS PostgreSQL | CPU, free storage, connections, PostgreSQL logs, backup/PITR posture | Confirms whether app failures are caused by database capacity, connectivity, or migration issues. |
| Redis/cache | replication group status, primary endpoint reachability from ECS, failover status, application cache errors | Confirms whether cache unavailability or stale cache data is causing impact. |
| Secrets | ECS task startup events and app logs that indicate reference resolution failures without exposing values | Confirms whether task-definition references point to valid user-owned values. |

The observability module models dashboard widgets and alarms for many of these signals. Committed examples intentionally keep alarm action lists empty; real paging and incident routing belong in user-owned configuration outside this repo.

## Bad container image

Symptoms:

- New tasks fail container health checks.
- Logs show startup errors, missing binaries, runtime exceptions, or incompatible app behavior.
- ALB target health drops after a task definition revision.
- ECS deployment events show repeated task replacement.

Rollback strategy:

1. Stop further promotion to other environments.
2. Identify the previous known-good image tag or digest from the last healthy task definition or release record.
3. Restore the service image reference in user-owned values or reviewed Terraform configuration.
4. Run repository validation before any manual rollout path.
5. Review the plan and confirm only the intended ECS task-definition image change is expected.
6. Roll out the previous image manually through the deployment process owned by the operator.
7. Keep the bad image available for investigation; do not retag it as good.

Verification steps:

- ECS service reaches steady state with expected desired/running task counts.
- Target group reports healthy targets for the service health path.
- ALB 5xx and latency return to baseline.
- Container logs show the previous version starting cleanly.
- No secret values or private registry credentials were added to this repository during investigation.

## Failing health checks

Symptoms:

- ALB target group reports unhealthy targets.
- ECS replaces tasks even though containers appear to start.
- The health endpoint path, port, matcher, startup time, or dependency readiness changed.

Rollback strategy:

1. Compare the new service configuration with the last healthy revision: `health_check_path`, container port, listener paths, target-group matcher, grace period, and container health command.
2. If the application health endpoint changed accidentally, restore the previous health-check path or reintroduce backward-compatible health behavior in the application image.
3. If startup now legitimately takes longer, prefer a reviewed forward fix to health-check timing rather than masking real failures.
4. If the target group points to the wrong port or path, roll back the service module inputs or listener wiring change.
5. Avoid changing security groups broadly to make health checks pass; first confirm the documented ALB-to-ECS service-port path.

Verification steps:

- Target health transitions to healthy for the expected path.
- ECS deployment events stop cycling tasks.
- The fixed default ALB response still handles unmatched routes.
- Application logs confirm the health endpoint response does not depend on unavailable optional dependencies.

## Failed ECS deployment

Symptoms:

- Deployment does not reach steady state.
- The deployment circuit breaker rolls back or repeatedly replaces tasks.
- Desired count and running count remain mismatched.
- Autoscaling changes make recovery ambiguous.

Rollback strategy:

1. Let the ECS deployment circuit breaker complete if it is already reverting to the prior task definition.
2. If automatic rollback does not restore service, manually select the previous stable task definition or reviewed Terraform input set.
3. Pause unrelated changes, including scaling-policy and environment-variable changes, until the service reaches steady state.
4. Keep desired count at a safe value that preserves capacity while avoiding runaway task churn.
5. Review IAM execution-role, image access, log group, subnet, security group, and secret-reference errors before retrying.

Verification steps:

- One active deployment remains and reports steady state.
- Desired/running task counts match the expected environment posture.
- ECS stopped-task reasons no longer show image pull, secret resolution, IAM, or health-check failures.
- ECS CPU/memory alarms return to normal or expected levels after traffic resumes.

## Bad environment variable/secret reference

Symptoms:

- Tasks fail at startup after config changes.
- Application logs show missing configuration, invalid secret reference, auth/signing failures, or connection string parsing errors.
- ECS stopped-task reasons indicate secret retrieval or permission failures.

Rollback strategy:

1. Confirm whether the issue is a non-secret environment variable, a secret ARN/reference, IAM permission, or the external secret value.
2. For non-secret variables, restore the previous placeholder-safe config shape in Terraform or user-owned values.
3. For secret references, restore the previous known-good reference name/ARN in user-owned configuration without exposing the secret value.
4. If the secret value itself was rotated badly, fix or revert the value outside this repository through the user-owned secret-management process.
5. Review IAM boundaries: ECS task execution role resolves injected secrets; application task role should only read secrets directly when explicitly reviewed.
6. Redeploy only after validation and plan review show no committed secret values.

Verification steps:

- New tasks start without secret-resolution errors.
- Application logs confirm dependency connections or signing checks succeed without printing secret contents.
- Secret-reference outputs remain metadata-only.
- No real secret value, private `.tfvars`, or credential artifact exists in the working tree.

## Database migration issue

Symptoms:

- A new service version fails against PostgreSQL after a schema change.
- RDS connections, CPU, locks, or error logs spike.
- Old and new application versions are incompatible with the same schema.
- Data integrity risk is possible.

Rollback strategy:

1. Stop service promotion and freeze additional writes if the application supports a safe maintenance/read-only mode outside this repo.
2. Determine whether the migration is backward-compatible, partially applied, or data-destructive.
3. Prefer a forward corrective migration when data has already changed and a clean reversal is unsafe.
4. If the application image is incompatible but data is safe, roll ECS back to the previous image that supports the current schema.
5. If the schema must be restored, use user-owned database backup, snapshot, or point-in-time recovery procedures after explicit data-loss and downtime review.
6. Keep migration credentials, SQL files with private details, and production data out of this public repo.

Verification steps:

- Application reads/writes succeed with the selected image/schema combination.
- RDS CPU, connections, storage, and PostgreSQL logs stabilize.
- Health checks pass without hiding failed background migrations.
- Stakeholders understand whether any data repair or replay is required.

## RDS incident

Symptoms:

- Services cannot connect to private PostgreSQL.
- RDS CPU, free storage, connections, or maintenance events indicate database pressure.
- Security group or subnet changes break connectivity.
- Backup, deletion-protection, or final snapshot posture becomes part of the response.

Rollback strategy:

1. Confirm whether the incident is connectivity, capacity, storage, credentials, migration, or RDS service health.
2. If a recent Terraform change modified RDS sizing, subnet groups, security groups, or deletion protection, review the plan and revert the smallest unsafe change.
3. If application traffic is overwhelming RDS, scale traffic or service concurrency down through a reviewed operational process rather than changing database access boundaries broadly.
4. If credentials changed, restore the previous known-good secret value or reference outside this repo.
5. For severe data incidents, use user-owned RDS backup/snapshot/PITR procedures with explicit approval and communication.
6. Preserve logs and event timelines for post-incident analysis.

Verification steps:

- ECS tasks in private subnets can connect through the ECS-to-RDS security group path only.
- RDS is still not publicly accessible.
- RDS alarms recover or are understood.
- Backup and deletion-protection settings match the environment's reviewed posture.

## Redis/cache issue

Symptoms:

- Cache endpoint is unavailable or failover is in progress.
- Application latency or error rate increases because cache reads/writes fail.
- Stale session, rate-limit, or tenant-cache data causes incorrect behavior.
- Dev unexpectedly enables cache resources or prod cache settings drift from review.

Rollback strategy:

1. Decide whether the cache is authoritative or safely disposable for the affected application behavior.
2. If the application can operate without cache, disable cache usage in application config outside this repo or roll back to a version that treats Redis as optional.
3. If a Terraform cache setting caused the issue, revert the smallest reviewed Redis input change such as enablement, replica/failover posture, parameter group, or encryption setting.
4. If stale data is the problem, use a user-owned cache invalidation or warm-up process outside this repo; do not store cache dumps or tenant data here.
5. For production-like use, preserve snapshots/final snapshot references when data matters.

Verification steps:

- Application logs show cache failures are resolved or safely bypassed.
- Redis replication group and endpoint status are healthy where enabled.
- ALB 5xx/latency and ECS CPU/memory return to expected levels.
- No public ingress was added to Redis security groups.

## ALB/routing issue

Symptoms:

- Requests reach the wrong service or fixed default response unexpectedly.
- A path pattern, priority, listener, target group, or security group change caused errors.
- Only one service path is affected while others remain healthy.

Rollback strategy:

1. Compare listener rule priorities and path patterns with the service catalog.
2. Restore the last known-good path pattern, listener rule priority, or target-group attachment.
3. Confirm the ALB security group still exposes only the reviewed listener ports and forwards only to the ECS service port.
4. If HTTPS/TLS was introduced in a user-owned environment, decide whether to revert listener changes or fix the certificate/DNS configuration outside this repo.
5. Do not route around private service placement by exposing ECS tasks, RDS, or Redis publicly.

Verification steps:

- `/carbon*` routes to `carbon-platform-api`, `/jobs*` routes to `job-runner-platform`, and `/saas*` routes to `multi-tenant-saas-api` in the committed example pattern.
- Unmatched paths receive the ALB fixed default response.
- Target group health and ALB 5xx metrics recover for the affected route.
- Security group boundaries still match the documented public-edge/private-service design.

## Verification checklist

Before declaring rollback complete:

- [ ] User impact is reduced or resolved for the affected route/service.
- [ ] ECS services are stable with expected desired/running counts.
- [ ] ALB target groups are healthy for the documented health paths.
- [ ] ALB 5xx, target response time, ECS CPU, ECS memory, RDS CPU, RDS free storage, and Redis signals are reviewed.
- [ ] Container logs show no repeated startup, health-check, secret-resolution, or dependency errors.
- [ ] RDS and Redis remain private; no public ingress was introduced during rollback.
- [ ] Secret values, credentials, private `.tfvars`, generated plans, and state files remain outside git.
- [ ] The rollback action and root-cause hypothesis are documented in user-owned incident notes.
- [ ] A forward-fix ticket or post-incident action exists for the bad change.

## Communication notes

Use clear, public-safe incident communication in user-owned channels:

- State the affected environment, service, route, and user-visible symptom.
- State the rollback decision, expected mitigation time, and verification signals.
- Separate confirmed facts from hypotheses.
- Call out data-risk decisions explicitly for database migrations, restores, and cache invalidation.
- Record whether any customer-visible data repair, replay, or follow-up migration is needed.
- Avoid posting secret values, private hostnames, real account IDs, or sensitive logs in public channels or this repository.

## Safety notes

- This guide is documentation only; it does not add rollback automation.
- Rollbacks that provision, modify, restore, or replace AWS resources are manual, user-owned, and can incur cost.
- CI and scripts must remain validation-only and must not run Terraform apply, destroy, import, or cloud CLI mutation commands.
- Keep rollback artifacts such as private values, state, generated plans, database dumps, logs with sensitive data, and credentials outside the repository.
- For production use, add reviewed paging, access controls, backup restore testing, migration tooling, DNS/TLS/WAF procedures, and game-day exercises outside this public lab.
