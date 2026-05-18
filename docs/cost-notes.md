# Cost Notes

This document captures qualitative cost awareness for the public-safe `platform-infra-lab` Terraform examples. It is not a bill estimate.

No exact current AWS prices are claimed here. AWS prices vary by region, date, usage pattern, discounts, and account configuration. For any real experiment, use the current AWS pricing pages or AWS Pricing Calculator from a user-owned account before provisioning.

Any real provisioning from this repository is optional, manual, user-owned, and can incur cost. CI and scripts remain validation-only and do not create or remove cloud resources.

## Cost documentation scope

The Terraform code models a reviewable AWS container platform with:

- VPC networking, public/private subnets, route tables, an internet gateway, and optional NAT gateway.
- A public Application Load Balancer.
- ECS/Fargate services for `carbon-platform-api`, `job-runner-platform`, and `multi-tenant-saas-api` using fake public images.
- Private RDS PostgreSQL.
- Optional private Redis/ElastiCache.
- CloudWatch log groups, dashboards, alarms, and RDS log exports.
- Metadata-only Secrets Manager references.

This document explains likely cost drivers and cleanup considerations if a user chooses to adapt the examples in a user-owned AWS account. It does not recommend provisioning the lab as-is; the committed images and secret values are placeholders.

## Cost drivers

Primary cost drivers are:

| Area | Why it matters | Repository posture |
| --- | --- | --- |
| Runtime resources | NAT gateways, ALBs, ECS tasks, RDS instances, and Redis nodes can bill while provisioned, even when mostly idle. | `dev` keeps several optional drivers disabled or small; `prod` demonstrates production intent and costs more if used. |
| Usage volume | Data transfer, request volume, log ingestion, metric/alarms, and API calls can increase with load. | The repo has no load-generation automation. Any traffic is user-owned. |
| Retained artifacts | Logs, snapshots, backups, and pending secret deletions can continue after an experiment. | Retention is configurable; cleanup remains manual and user-owned. |
| Availability choices | Multi-AZ, replicas, higher desired counts, and longer retention improve resilience but increase cost. | `prod` examples intentionally show stronger posture than `dev`. |
| External resources | Real state backends, user-owned buckets, KMS keys, image registries, DNS, WAF, and paging routes are outside this repo. | Not created by committed automation; review separately if added. |

Cost review should happen before any optional manual plan or provisioning step, and again before leaving test resources running overnight or across weekends.

## NAT gateway cost implications

The network module can create one NAT gateway when `enable_nat_gateway = true`.

Cost implications:

- NAT gateways are a meaningful ongoing cost driver because they can bill while running and for processed traffic.
- Private ECS tasks may need outbound access for image pulls, CloudWatch Logs, ECS APIs, Secrets Manager, SSM Parameter Store, and package/service calls.
- A NAT gateway also uses an Elastic IP allocation; orphaned or unattached addresses should be checked during cleanup.
- Data processed through NAT can become significant if services download large images, call external APIs heavily, or emit traffic through public endpoints.

Repository posture:

- `dev` sets `enable_nat_gateway = false` to keep the example cost-aware by default. That means a real manually provisioned dev service may need VPC endpoints or a reviewed egress pattern before it can pull images or publish logs from private subnets.
- `prod` sets `enable_nat_gateway = true` to demonstrate private subnet egress intent, not to recommend running it without cost review.

Cost-control ideas:

- Keep NAT disabled for static validation and documentation review.
- Prefer short-lived experiments.
- Consider AWS PrivateLink/VPC endpoints in a real design for specific AWS services, while remembering endpoints can have their own cost.
- Avoid routing high-volume internal service traffic through NAT.

## RDS cost implications

The RDS PostgreSQL module models a private `aws_db_instance` with RDS-managed master credentials, backup settings, storage variables, optional Multi-AZ, log exports, deletion protection, and optional Performance Insights.

Cost implications:

- The database instance class and continuous runtime are the main drivers.
- Allocated storage, storage autoscaling ceilings, storage type, retained backups, and final snapshots can add cost.
- Multi-AZ improves availability but can materially increase cost versus a single-AZ dev database.
- CloudWatch PostgreSQL log exports increase log ingestion and retention costs.
- Performance Insights/Database Insights and enhanced monitoring can add cost depending on configuration and retention.
- KMS usage may matter if a user-owned key is supplied.

Repository posture:

- `dev` uses a small single-AZ shape, low initial storage, short backup retention, deletion protection disabled, skipped final snapshot, and Performance Insights disabled.
- `prod` demonstrates production intent with Multi-AZ, deletion protection, final snapshot posture, longer backup retention, larger storage ceilings, and Performance Insights enabled.

Cost-control ideas:

- Do not provision RDS for a documentation-only review.
- Keep dev databases small, single-AZ, and short-lived.
- Review backup retention and final snapshot needs before experiments.
- Remove retained snapshots and automated backups only when safe and user-owned.
- Treat production database settings as an availability example, not a cost-optimized default.

## ALB cost implications

The load-balancer module creates an internet-facing Application Load Balancer with an HTTP listener, optional HTTPS listener variables, optional access logs, and service listener-rule wiring.

Cost implications:

- An ALB can bill while provisioned.
- Request rate, processed bytes, active connections, rule evaluations, and TLS usage can influence load balancer capacity cost.
- Public edge data transfer can add cost depending on traffic patterns.
- Optional ALB access logs require a user-owned S3 bucket and can add storage/request costs.
- Deletion protection can prevent quick cleanup if enabled and must be handled deliberately.

Repository posture:

- Both environments model a public ALB because the architecture needs a public edge.
- `dev` disables ALB deletion protection and access logs by default.
- `prod` enables ALB deletion protection to show production safety intent, while HTTPS remains placeholder-only because no real certificate ARN is committed.

Cost-control ideas:

- Avoid running the ALB continuously for portfolio review.
- Keep access logs disabled unless you have a reviewed bucket lifecycle policy.
- Use short test windows and low traffic.
- Confirm no duplicate or orphaned ALBs remain after experiments.

## ECS Fargate cost drivers

The ECS service module creates Fargate task definitions and services, CloudWatch log groups, target groups, listener rules, health checks, and optional target-tracking autoscaling.

Cost implications:

- Fargate cost is driven by running task count, vCPU, memory, runtime duration, operating system/architecture choices, and region.
- Desired count and autoscaling maximum capacity multiply cost across services.
- The examples model three services, so even small task sizes can add up when all are running.
- Large image pulls and outbound calls can add network/NAT or data transfer cost.
- Failed deployments can still create task churn, logs, and health-check traffic.

Repository posture:

- `dev` uses one small task per example service and autoscaling ranges kept low.
- `prod` uses larger task sizes, desired count of two per service, and wider autoscaling ranges to demonstrate production intent.
- The committed image names are fake public placeholders; they are not intended to run a real workload from this repo.

Cost-control ideas:

- Do not run all three services unless the experiment requires it.
- Keep desired counts and autoscaling maxima low in dev.
- Use immutable, right-sized images in a real fork to reduce pull time and failure loops.
- Monitor service events and stop failed experiments quickly.

## CloudWatch log/metric costs

The observability pattern uses ECS log groups, RDS log exports, CloudWatch dashboards, CloudWatch alarms, and service metrics.

Cost implications:

- CloudWatch Logs costs depend on ingestion volume and retention duration.
- Verbose application logging, crash loops, and high request volume can increase log ingestion quickly.
- Longer retention keeps log data billable for longer.
- CloudWatch dashboards and alarms can add recurring costs.
- RDS PostgreSQL log exports add database log volume to CloudWatch Logs.
- User-owned custom metrics, Logs Insights queries, or alarm notification routes can add additional cost if introduced outside this repo.

Repository posture:

- `dev` uses short log retention.
- `prod` uses longer log retention and more production-like alarms.
- Alarm action lists are intentionally empty in committed examples; real notification routes belong outside this public repo.

Cost-control ideas:

- Keep dev log retention short.
- Avoid debug-level logging in long-running environments.
- Investigate and stop crash loops quickly.
- Review whether every dashboard, alarm, and log export is needed for the environment.
- Use log filtering and structured logs to reduce noisy output in real services.

## Redis/ElastiCache costs

The Redis cache module models an optional private ElastiCache Redis/Valkey-style replication group with encryption, subnet group, security group input, replicas, Multi-AZ/failover settings, snapshots, and final snapshot options.

Cost implications:

- ElastiCache nodes can bill while running, even when idle.
- Total node count is the primary node plus replicas.
- Multi-AZ and automatic failover require replica capacity and increase cost.
- Snapshot retention and final snapshots can create retained storage costs.
- Cache traffic and KMS usage may add cost depending on configuration.

Repository posture:

- `dev` sets `enable_redis = false` by default and uses a small optional node shape for experiments.
- `prod` sets `enable_redis = true` with one replica, Multi-AZ/failover intent, encryption, snapshot retention, and final snapshot posture.

Cost-control ideas:

- Keep Redis disabled unless a service experiment needs it.
- Avoid replicas and Multi-AZ for short dev experiments unless testing failover specifically.
- Review snapshot retention before enabling the cache.
- Confirm final snapshots are either intentionally retained or cleaned up after testing.

## Dev versus prod trade-offs

The environments are intentionally different to show platform review thinking.

`dev` is designed for low-cost review:

- NAT gateway disabled.
- Redis disabled.
- One small Fargate task per service.
- Shorter CloudWatch log retention.
- Smaller single-AZ RDS posture.
- Shorter backup retention.
- Deletion protection generally disabled for easier cleanup.

`prod` is designed to demonstrate production intent:

- NAT gateway enabled for private egress.
- Redis enabled with replica/failover posture.
- Higher desired counts and autoscaling ceilings.
- Longer log and backup retention.
- Multi-AZ RDS posture.
- Deletion protection and final snapshot posture.
- Performance Insights enabled.

Trade-off guidance:

- Use `dev` for validation and short-lived experiments only after cost review.
- Treat `prod` as a reviewable pattern, not a default environment to provision.
- Before promoting from dev to prod, review every setting that increases runtime, retention, replica count, or deletion protection.
- Production hardening features can reduce operational risk while increasing cost and cleanup complexity.

## Cleanup checklist

No cleanup automation is provided by this repository. If a user manually provisions resources, cleanup is also user-owned and should be reviewed before and after removal.

Before cleanup:

- [ ] Confirm you are operating in the intended user-owned account and region.
- [ ] Confirm Terraform state and backend settings are available outside this repo.
- [ ] Review deletion protection settings for ALB and RDS.
- [ ] Decide whether final RDS and Redis snapshots are required.
- [ ] Export or retain any logs required for the user-owned experiment.
- [ ] Communicate downtime if real users or stakeholders are involved.

During cleanup:

- [ ] Stop test traffic and remove temporary DNS or routing outside this repo.
- [ ] Remove ECS services/tasks, ALB, target groups, NAT gateway, RDS, Redis, secrets metadata, dashboards, and alarms through a reviewed user-owned workflow.
- [ ] Watch for cleanup blockers caused by deletion protection, final snapshot settings, dependencies, or IAM permissions.
- [ ] Keep generated plans, state, credentials, and real variable files outside the repository.

After cleanup:

- [ ] Check for retained RDS snapshots, Redis snapshots, automated backups, and final snapshots.
- [ ] Check CloudWatch log groups and retained log data.
- [ ] Check S3 buckets used for ALB access logs or Terraform state.
- [ ] Check DynamoDB tables or lock resources used by a real Terraform backend.
- [ ] Check unattached Elastic IP addresses, ENIs, security groups, and KMS keys.
- [ ] Check Secrets Manager resources waiting through a recovery window.
- [ ] Check user-owned image registries for large unused images.
- [ ] Review tags such as `Project`, `Environment`, and `CostUse` to find leftovers.

## How to avoid accidental spend

Use validation-only workflows whenever possible:

- Run `bash scripts/quality-gate.sh` for portfolio review instead of provisioning.
- Use `terraform init -backend=false` and `terraform validate` for local structural checks.
- Do not configure AWS credentials in this repository for validation-only work.
- Do not add scripts or CI jobs that run cloud mutation commands.
- Keep real `.tfvars`, state, generated plans, credentials, and backend settings outside the repo.

If you choose to experiment manually:

- Use a user-owned sandbox account with budgets, alerts, and short-lived credentials.
- Start with `dev`, not `prod`.
- Keep NAT, Redis, Multi-AZ, higher desired counts, and long retention disabled unless specifically testing them.
- Replace fake images and create real secret values only in a private, user-owned workflow.
- Review a Terraform plan before any manual provisioning.
- Set a calendar reminder or time box for cleanup.
- Review CloudWatch logs, task churn, and failed health checks during the test so failures do not run unnoticed.
- Clean up retained snapshots, logs, access-log buckets, backend resources, and pending secret deletions after the experiment.

For command-level workflow details, see the [deployment guide](deployment.md), [operations guide](operations.md), and [runbook](runbook.md).
