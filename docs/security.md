# Security guide

This guide documents the public-safe security posture for `platform-infra-lab`. The repository is a portfolio Terraform lab, not a production platform. It models security boundaries and review habits without committing secrets, private infrastructure details, or automation that mutates cloud resources.

Use this document together with:

- [`docs/secrets.md`](secrets.md) for the secret-reference pattern.
- [`docs/architecture.md`](architecture.md) for request flow and component placement.
- [`docs/deployment.md`](deployment.md) for validation-first manual review steps.
- [`docs/operations.md`](operations.md) and [`docs/runbook.md`](runbook.md) for operational response.

## Security scope and assumptions

The repository demonstrates:

- AWS/Terraform infrastructure-as-code structure.
- Private ECS service placement behind a public Application Load Balancer.
- Private PostgreSQL/RDS and optional private Redis/ElastiCache patterns.
- IAM separation between ECS runtime and application permissions.
- Secret references through AWS-native services rather than committed values.
- Validation-only CI and local guardrails.

The repository does not provide:

- Production certification or a complete compliance control set.
- Real account configuration, DNS, TLS certificates, WAF rules, paging routes, or secrets.
- Automated provisioning, teardown, imports, migrations, or incident remediation.
- A guarantee that the example settings are sufficient for every production workload.

Any real provisioning is optional, manual, user-owned, and can incur cost.

## No committed secrets

No committed secrets are allowed in this project.

Do not commit:

- AWS access keys, session tokens, credentials files, or local cloud profiles.
- Database passwords, connection strings, API keys, JWT signing keys, or Redis AUTH tokens.
- SSH private keys, TLS private keys, kubeconfig files, or `.env` files with values.
- Private URLs, internal hostnames, employer details, or real cloud account identifiers.

Repository controls:

- `scripts/check-public-safety.sh` scans for private-key material, AWS access-key-looking tokens, credential-looking files, `.env` files, and non-placeholder account IDs.
- `scripts/check-no-terraform-state.sh` rejects real `.tfvars`, `.tfstate`, generated plan files, and local `.env` files.
- Examples use public-safe names and fake images such as `public.ecr.aws/example/...:demo`.
- Secret values are never represented in committed Terraform, Markdown, scripts, or CI.

If a real secret is accidentally placed in the working tree, remove it before committing, rotate it in the owning system, and treat the incident as a credential exposure.

## No Terraform state in git

Terraform state and generated plan files must not be committed.

State can contain sensitive details, provider-computed attributes, resource identifiers, endpoint names, and references that are inappropriate for a public portfolio repository. Generated plan files can also expose intended changes and environment-specific details.

Repository controls:

- `.gitignore` excludes Terraform state, backup state, generated plans, local override files, and real variable files.
- `scripts/check-no-terraform-state.sh` fails if `.tfstate`, `.tfplan`, real `.tfvars`, or local `.env` files appear in the working tree.
- Environment roots include `backend.example.tf` only. Real backend configuration belongs outside this repository.
- `terraform.tfvars.example` files document shape and placeholder values only; they are not real variable files.

For optional user-owned provisioning, keep backend configuration, state files, plan files, and private variable values outside the repository.

## IAM role separation

The Terraform modules model separate ECS roles:

- **Task execution role** — used by the ECS/Fargate platform to pull images, write logs, and resolve ECS-injected secret references.
- **Application task role** — assumed by the running application container when it calls AWS APIs directly.

This separation keeps platform runtime permissions distinct from application permissions. A service that only receives secrets through ECS task-definition injection should not need broad AWS SDK access through the application task role.

The IAM module models:

- Trust policies scoped to `ecs-tasks.amazonaws.com`.
- AWS-managed execution policy attachment for standard ECS runtime needs.
- Optional inline policies for secret-reference ARNs supplied by module inputs.
- Empty optional extra permission lists by default in committed examples.

Production users should review each service role independently and avoid sharing one broad application role across unrelated services.

## Least-privilege intent

The repository demonstrates least-privilege thinking, but it remains an example that requires production review.

Current least-privilege patterns include:

- Security group rules use source security group references instead of broad public access for private tiers.
- RDS and Redis accept traffic only from the ECS service security group on their expected ports.
- Secret-read IAM statements are scoped to supplied ARNs rather than hard-coded wildcard account paths.
- Alarm action lists default to empty so no real SNS topic, webhook, account ID, or incident target is committed.
- KMS key inputs default to `null` in public examples so real key ARNs are not published.
- Dev/prod settings are explicit, reviewable, and environment-specific.

Before production use, review IAM Access Analyzer findings, permissions boundaries, service control policies, KMS key policies, cross-account access, image registry access, and whether any wildcard action or resource remains necessary.

## Private database/cache

The data tier is private by design.

RDS PostgreSQL posture:

- The RDS module uses private subnet IDs from the network module.
- `publicly_accessible` is fixed to `false`.
- The environment passes the RDS security group from the security-groups module.
- PostgreSQL ingress is scoped from the ECS service security group to the configured database port.
- The module does not accept or output raw database password values.
- RDS-managed master credentials are represented as Secrets Manager references when a user manually provisions the lab.

Redis/ElastiCache posture:

- The Redis module uses private subnet IDs from the network module.
- Redis can be disabled at the environment level.
- Redis ingress is scoped from the ECS service security group to the configured cache port.
- Encryption settings default to enabled in the module pattern.
- No Redis AUTH token, ACL user, or connection-string secret value is committed.

Private placement does not remove the need for database users, migration roles, audit logging, TLS requirements, backup review, cache data classification, or secret rotation in real environments.

## Public ALB boundary

The Application Load Balancer is the modeled public edge.

Current boundary:

- Public internet ingress is allowed only to the load balancer security group.
- ECS tasks are placed in private subnets and do not receive public task IPs by default.
- ALB listener rules route reviewed paths to ECS service target groups.
- The ALB-to-ECS rule permits only the configured service port.
- RDS and Redis are not attached to public subnets and do not accept public CIDR ingress.

Production requirements not committed here include a real ACM certificate ARN, HTTPS enforcement, DNS ownership, WAF or Shield decisions, access-log bucket ownership, bot/rate-limit controls, and public endpoint monitoring.

## Secret reference pattern

This project uses secret references, not secret values.

The Secrets Manager reference module creates metadata-only `aws_secretsmanager_secret` resources for ECS injection. It deliberately does not create `aws_secretsmanager_secret_version` resources, does not accept `secret_string`, and does not generate secret values in Terraform.

The ECS service module receives `secret_references` as environment-variable-name to ARN mappings. ECS resolves those references at task startup through the task execution role. The application receives runtime values inside the container, while Terraform and git store only reference metadata.

Secret lifecycle ownership remains outside this public repository:

- Initial secret creation.
- Emergency rotation.
- Scheduled rotation.
- Database credential migration sequencing.
- KMS key ownership.
- Audit and break-glass access.
- Rollback for bad rotated values.

See [`docs/secrets.md`](secrets.md) for the detailed secret-reference flow.

## CI validation-only posture

GitHub Actions and local scripts are validation-only.

The quality gate runs checks such as:

- Shell syntax validation.
- Public-safety scans.
- No-state/no-plan/no-real-variable-file scans.
- No cloud mutation automation scans.
- Markdown link sanity checks.
- Terraform formatting, backend-disabled initialisation, and Terraform validation when Terraform is available.

CI must not run Terraform apply, destroy, import, cloud deployment commands, or destructive cloud CLI operations. The workflow installs Terraform for validation but does not configure cloud credentials or mutate AWS resources.

This posture keeps the repository safe to review publicly and prevents pull requests from creating, changing, or deleting infrastructure.

## Manual apply warnings

This repository intentionally does not provide apply scripts or deploy jobs.

If a user chooses to adapt and provision the lab, that action is:

- Optional.
- Manual.
- User-owned.
- Performed from a user-owned AWS account.
- Potentially billable.
- Outside the safety guarantees of validation-only CI.

Before any optional manual provisioning, review:

- Cloud identity, account, region, and state backend.
- Plan output for public exposure, IAM scope, deletion protection, and cost drivers.
- Secret values and backend values stored outside this repository.
- Cleanup expectations for ALB, NAT gateway, ECS tasks, RDS, Redis, snapshots, logs, and alarms.

Use [`docs/deployment.md`](deployment.md) for the validation-first review process and [`docs/cost-notes.md`](cost-notes.md) for qualitative spend considerations.

## Production hardening gaps

The lab intentionally leaves production-specific controls for the operator to design and own.

Important gaps to review before real use:

- TLS termination, HTTPS redirects, HSTS, DNS ownership, and certificate rotation.
- WAF, DDoS posture, rate limiting, bot controls, and public endpoint abuse monitoring.
- VPC endpoint strategy, NAT egress controls, explicit outbound security group rules, and third-party API allow lists.
- Image provenance, vulnerability scanning, SBOMs, signature verification, and private registry access.
- Per-service IAM task roles, permissions boundaries, KMS key policies, and Access Analyzer findings.
- Secret creation, rotation, emergency revocation, audit logging, and break-glass process.
- Database user separation, migration credentials, connection pooling, audit logs, backup restore testing, and point-in-time recovery objectives.
- Redis AUTH/ACL decisions, TLS client compatibility, eviction policy, parameter groups, and cache data classification.
- CloudWatch log redaction, retention, metric coverage, alarm routing, paging escalation, and incident ownership.
- Data classification, tenant isolation, privacy review, compliance requirements, and vulnerability management.
- Disaster recovery objectives, multi-region strategy, backup restore drills, and game days.

These gaps are documented so reviewers can see the boundary between portfolio demonstration and production readiness.

## Access review checklist

Use this checklist when reviewing a real fork, private environment, or optional user-owned deployment:

- [ ] Repository contains no secrets, real `.tfvars`, state, plan files, cloud credentials, SSH keys, kubeconfigs, or private `.env` files.
- [ ] Terraform state backend is private, encrypted, access-controlled, and not committed.
- [ ] Only intended operators can run manual Terraform plan/apply in the target AWS account.
- [ ] ECS task execution role grants only runtime permissions and scoped secret-reference reads.
- [ ] ECS application task roles are service-specific and grant only AWS API permissions the application actually needs.
- [ ] Secret ARNs, KMS keys, and parameter paths are scoped to the environment and service.
- [ ] ALB is the only public ingress path; ECS, RDS, and Redis remain private.
- [ ] Security group ingress and egress match documented request and dependency flows.
- [ ] RDS is not publicly accessible and deletion protection, backups, final snapshots, and monitoring match the environment risk.
- [ ] Redis is enabled only when needed and has reviewed encryption, failover, auth/ACL, and data-retention posture.
- [ ] CloudWatch logs do not contain secret values or sensitive tenant data.
- [ ] Alarm actions and dashboards are visible only to the intended operators.
- [ ] CI remains validation-only and has no cloud mutation credentials or deployment steps.
- [ ] Access reviews include IAM users/roles, GitHub repository permissions, state backend permissions, secret administrators, and break-glass users.

## Threat model summary

| Threat | Repository mitigation | Remaining production work |
| --- | --- | --- |
| Secret exposure through git | No committed values, public-safety scans, metadata-only secret references, example files only. | Manage real secret creation, rotation, audit, KMS, and incident response outside this repo. |
| Terraform state leakage | State/plan guardrails and backend examples only. | Use private encrypted remote state with least-privilege backend access and audit logging. |
| Public access to private services | ALB-only public boundary, private ECS/RDS/Redis placement, security group references. | Add TLS, WAF, DNS controls, egress review, and continuous exposure monitoring. |
| Overbroad IAM permissions | Separate execution/task roles and scoped optional secret-reference ARNs. | Review per-service roles, remove wildcards, apply boundaries, and analyze findings. |
| Unauthorized or accidental cloud changes | Validation-only CI and no mutation commands in automation. | Restrict who can run manual applies and protect state/backend credentials. |
| Data loss or unsafe rollback | RDS backup/deletion-protection variables and rollback/runbook documentation. | Test restores, define RPO/RTO, own migrations, and rehearse incident procedures. |
| Cost or resource sprawl | Cost notes, no automatic provisioning, explicit cleanup guidance. | Use budgets, tags, lifecycle policies, and account-level cost controls in real environments. |
| Observability data leakage | Logs/dashboards modeled without committing log contents or routing targets. | Redact logs, restrict dashboard access, route alarms securely, and define retention policy. |

## Validation

Run the full local quality gate after security-relevant changes:

```bash
bash scripts/quality-gate.sh
```

The quality gate validates this guide exists, checks key security topics, and runs the repository guardrails. CI runs the same validation-only gate without applying infrastructure.
