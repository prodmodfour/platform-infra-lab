# Deployment guide

This guide explains how to validate and manually review the Terraform environments in this public-safe AWS container platform lab. It is intentionally validation-first: this repository does not provide one-click deployment, deployment scripts, or CI jobs that mutate cloud infrastructure.

Any real provisioning is optional, manual, user-owned, and can incur cost. The committed examples use fake images, placeholder secret references, example backend settings, and public-safe names only.

## Scope and safety posture

Use this guide for:

- local validation before a pull request or portfolio review
- manual Terraform initialisation with backend access disabled
- optional user-owned plan review in a real AWS account
- service image update review for the three example ECS services
- environment promotion thinking between `dev` and `prod`
- post-deploy health and observability checks if a user chooses to provision resources manually

This guide does not add automation for provisioning. Scripts and GitHub Actions remain validation-only and must not run Terraform apply, destroy, import, or cloud CLI mutation commands.

## Pre-deploy checklist

Before any optional manual provisioning, confirm:

- [ ] You are using a user-owned AWS account, not an employer or shared private account.
- [ ] You understand that AWS resources such as NAT gateways, ALBs, ECS tasks, RDS, ElastiCache, CloudWatch logs, and snapshots can continue billing until cleaned up.
- [ ] `bash scripts/quality-gate.sh` passes from the repository root.
- [ ] Terraform changes have been reviewed as code, including module inputs, outputs, security groups, IAM policies, and environment differences.
- [ ] No real `.tfvars`, Terraform state, generated plan files, credentials, SSH keys, kubeconfigs, or `.env` files are inside the repository working tree.
- [ ] Real secret values already exist outside this repository or will be created by a secure user-owned process. This repo only models secret references.
- [ ] Any real backend state configuration is user-owned and not committed.
- [ ] The example image names under `public.ecr.aws/example/...:demo` have been replaced in a user-owned change or external values file if you expect tasks to run successfully.
- [ ] Database migration steps are backward-compatible, reviewed separately from Terraform, and have a rollback plan.
- [ ] Alarm actions, paging routes, DNS, TLS certificates, WAF rules, and production access controls have been reviewed outside this public lab before production use.

## Required local tools

For validation and review:

- `bash`
- `git`
- `python3` for Markdown link checks
- Terraform `>= 1.6.0`

For optional user-owned plan or provisioning:

- AWS credentials configured outside this repo, preferably through SSO or a short-lived role
- permission to manage the resources described by the Terraform environment
- optional AWS CLI for read-only checks such as identity, ECS service state, target health, and CloudWatch alarm status
- access to any user-owned container registry that stores real service images

Do not store credentials, session files, backend secrets, or real variable files in this repository.

## Run validation

Run the full local quality gate from the repository root:

```bash
bash scripts/quality-gate.sh
```

The quality gate checks repository structure, public-safety guardrails, forbidden state/plan/real variable files, cloud mutation automation, Markdown links, shell syntax, Terraform formatting, and Terraform validation. Terraform validation uses backend-disabled initialisation, so local validation does not require a remote state backend.

If Terraform is not installed locally, the Terraform check warns and skips. GitHub Actions installs Terraform and runs the validation-only quality gate.

## Initialise Terraform manually

Use backend-disabled initialisation for local validation or code review:

```bash
cd infra/terraform/environments/dev
terraform init -backend=false
terraform validate
```

Repeat the same pattern for `prod` when reviewing production-intent configuration:

```bash
cd infra/terraform/environments/prod
terraform init -backend=false
terraform validate
```

For optional user-owned provisioning, the environment roots contain public-safe `backend.example.tf` files. They are examples only. A real operator must provide user-owned backend settings without committing them. One safe pattern is to pass backend values at initialisation time from a private shell session or secure wrapper outside this repo:

```bash
cd infra/terraform/environments/dev
terraform init \
  -backend-config="bucket=<user-owned-state-bucket>" \
  -backend-config="key=platform-infra-lab/dev/terraform.tfstate" \
  -backend-config="region=<aws-region>" \
  -backend-config="dynamodb_table=<user-owned-lock-table>" \
  -backend-config="encrypt=true"
```

Use placeholder names above as prompts only. Do not commit real backend bucket names, lock table names, account IDs, or generated state.

## Review a plan

A Terraform plan is a review artifact, not an automated deployment step. Run it only from a user-owned shell with the intended AWS identity.

For public-safe structural review with example values:

```bash
cd infra/terraform/environments/dev
terraform plan -var-file=terraform.tfvars.example
```

For a real user-owned environment, keep values outside the repository and reference them by absolute path:

```bash
cd infra/terraform/environments/dev
terraform plan -var-file=/secure/user-owned/path/dev.tfvars
```

Plan review checklist:

- Confirm the account and region are the intended user-owned targets.
- Confirm VPC, subnet, route table, and NAT gateway changes match the environment posture.
- Confirm only the ALB is public-facing; ECS tasks, RDS, and Redis remain private.
- Confirm security group ingress follows the documented boundary: internet to ALB, ALB to ECS, ECS to PostgreSQL/Redis.
- Confirm IAM policies are scoped to the expected secret references and do not include broad wildcard access beyond the reviewed pattern.
- Confirm the RDS instance is not publicly accessible and deletion protection/final snapshot settings match the environment.
- Confirm Redis is disabled for dev by default and explicitly reviewed if enabled.
- Confirm CloudWatch log retention, dashboards, alarms, and empty or user-owned alarm action lists are expected.
- Confirm image tags, health check paths, listener priorities, and path patterns match the service rollout plan.
- Confirm no secret values appear in plan output, terminal logs, or saved artifacts.

If you save a plan with `-out`, write it outside the repository and delete it after review. Generated plan files must not be committed.

## Manual apply warning

This repository intentionally does not automate apply.

If, and only if, you choose to provision the lab in a user-owned AWS account, run the apply command manually from the relevant environment directory after validation and plan review. This action is optional, manual, user-owned, and can incur cost.

```bash
# Optional manual step only. Do not put this in scripts or CI.
terraform apply
```

Before running any manual apply, remember:

- The committed service images are fake placeholders and may not start real workloads.
- Secret containers are metadata-only; real values must exist outside this repo before ECS tasks that depend on them can run.
- RDS, Redis, NAT gateways, ALBs, logs, backups, and snapshots can continue billing until removed by the user.
- Production use requires additional review for TLS, DNS, WAF, egress, backups, paging, IAM boundaries, migration automation, and incident response.

## Service image update flow

Use this flow for a reviewed image change to one of the example services:

1. Build and scan the application image outside this repository.
2. Push the image to a user-owned registry. Prefer immutable tags or image digests over mutable `latest` tags.
3. Update the relevant service image reference in a user-owned values file outside the repo, or update the public-safe example only when the value remains fake and safe to publish.
4. Keep real registry URLs, account-specific image names, and deployment credentials out of this repository unless they are intentionally public placeholders.
5. Run `bash scripts/quality-gate.sh`.
6. Run `terraform plan` with the reviewed values and confirm the ECS task definition revision, desired count, health path, listener rule, secret references, and log group settings.
7. If manually applying, deploy during a reviewed change window and monitor ECS deployment events, ALB target health, CloudWatch logs, and alarms.
8. Keep the previous image tag or digest available for rollback.

Service-specific review notes live in [`docs/service-examples.md`](service-examples.md).

## Environment promotion approach

`dev` and `prod` use the same module structure with different defaults and example values. Promote changes deliberately:

1. Validate the Terraform change locally and in CI.
2. Review the `dev` plan first with user-owned values.
3. Deploy to `dev` manually only if the operator accepts the cost and operational responsibility.
4. Verify service health, logs, dashboard widgets, and alarms.
5. Promote the same reviewed image digest and compatible configuration to `prod` values.
6. Compare dev/prod differences before production rollout, especially desired count, autoscaling bounds, NAT posture, Redis enablement, RDS deletion protection, backup retention, ALB deletion protection, and alarm routing.
7. Keep environment-specific secrets and backend settings outside this repository.
8. Do not automatically promote by running CI-driven apply; promotion remains a manual, reviewed action.

## Migration considerations

Application and database migrations are intentionally outside this Terraform lab, but a real rollout should plan them before changing service images.

Use these principles:

- Prefer backward-compatible expand/contract migrations.
- Apply schema changes separately from service image changes when risk is high.
- Confirm RDS backups, deletion protection, and final snapshot settings match the risk profile.
- Confirm applications can tolerate both old and new schema versions during rolling ECS deployments.
- Keep migration credentials and connection strings outside this public repo.
- For long-running migrations, define a timeout, verification query, abort criteria, and communication plan.
- For cache changes, decide whether Redis data can be flushed, warmed, or ignored during rollback.
- If migration safety is uncertain, stop before applying infrastructure or service changes.

## Post-deploy checks

If a user-owned manual deployment is performed, verify the platform before declaring success:

- ECS services reach steady state with the expected desired/running task counts.
- ALB target groups report healthy targets for `/health`, `/healthz`, or `/ready` as documented per service.
- The public ALB listener routes only the expected path patterns.
- CloudWatch log groups receive application logs without secrets or sensitive tenant data.
- CloudWatch dashboard widgets show ECS CPU/memory, ALB 5xx/unhealthy target signals, and RDS capacity signals.
- Alarms are either intentionally actionless for lab review or routed to a user-owned incident channel.
- RDS is private, encrypted, backed up, and reachable only from ECS security groups.
- Redis, if enabled, is private and matches the reviewed replica/failover posture.
- Secret references resolve for ECS task startup without exposing secret values in logs.
- No unexpected NAT gateway, snapshot, log retention, or orphaned resource cost drivers remain after testing.

If any check fails, stop promotion and use the [rollback guide](rollback.md) to choose the smallest safe rollback path.
