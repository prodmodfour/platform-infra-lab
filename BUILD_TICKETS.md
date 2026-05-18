# BUILD_TICKETS.md

AUTOMATION_STATUS: IN_PROGRESS

Ticket statuses:

- TODO
- IN_PROGRESS
- DONE
- BLOCKED

The build loop must select the lowest-numbered TODO or IN_PROGRESS ticket.

---

## 000 — Bootstrap repository skeleton

Status: DONE

Create the initial repository structure.

Required:

- `README.md`
- `.gitignore`
- `scripts/`
- `docs/`
- `docs/decisions/`
- `docs/diagrams/`
- `infra/`
- `infra/terraform/`
- `infra/terraform/modules/`
- `infra/terraform/environments/`
- basic placeholder docs
- public-safe project framing

The README must clearly state:

- independent public portfolio project
- infrastructure-as-code/platform engineering focus
- AWS/Terraform as the primary direction
- no automatic cloud deployment
- no committed secrets
- no Terraform state
- optional manual apply can incur cost
- intended backend/platform/SRE skills demonstrated

Run `scripts/quality-gate.sh`.

Commit when complete.

---

## 001 — Add validation scripts and guardrails

Status: DONE

Implement reusable validation scripts:

- `scripts/check-public-safety.sh`
- `scripts/check-no-terraform-state.sh`
- `scripts/check-no-cloud-mutations.sh`
- `scripts/check-terraform.sh`
- update `scripts/quality-gate.sh`

Checks should catch:

- `.tfstate`
- `.tfplan`
- `.tfvars` except `.tfvars.example`
- `.env`
- private key files
- AWS credential-looking files
- real-looking account IDs where practical
- automated `terraform apply`
- automated `terraform destroy`
- automated `terraform import`
- cloud CLI deploy/mutation commands in scripts or CI

Terraform check should run:

- `terraform fmt -recursive -check`
- `terraform init -backend=false`
- `terraform validate`

for every Terraform environment when Terraform is available.

If Terraform is not available locally, warn clearly but do not fail. CI will install Terraform later.

Add tests or self-checks where practical.

Run `scripts/quality-gate.sh`.

Commit when complete.

---

## 002 — Add Terraform repository conventions

Status: DONE

Create:

- `infra/terraform/README.md`
- `infra/terraform/modules/README.md`
- `infra/terraform/environments/README.md`
- common naming/tagging guidance
- module interface conventions
- environment conventions
- backend configuration guidance

Document:

- no real backend config committed
- use `backend.example.tf`
- use `terraform.tfvars.example`
- never commit state
- validation-only CI
- manual apply only

Run `scripts/quality-gate.sh`.

Commit when complete.

---

## 003 — Add AWS provider/environment skeletons

Status: DONE

Create Terraform environments:

- `infra/terraform/environments/dev/`
- `infra/terraform/environments/prod/`

Each environment should include:

- `providers.tf`
- `main.tf`
- `variables.tf`
- `outputs.tf`
- `backend.example.tf`
- `terraform.tfvars.example`
- `README.md`

Use public-safe placeholder values only.

Do not include real account IDs, backend bucket names, or secrets.

Dev/prod should use the same modules but different variable defaults/examples.

Run `scripts/quality-gate.sh`.

Commit when complete.

---

## 004 — Add network module

Status: DONE

Create `infra/terraform/modules/network/`.

The module should model:

- VPC
- public subnets
- private subnets
- route tables where practical
- NAT gateway enable/disable variable
- internet gateway where practical
- common tags
- outputs for subnet IDs, VPC ID, and CIDRs

Use public-safe defaults and examples.

Add module README explaining:

- public versus private subnet intent
- cost implications of NAT gateways
- production hardening gaps

Wire the module into dev/prod environments.

Run `scripts/quality-gate.sh`.

Commit when complete.

---

## 005 — Add security groups module or security group resources

Status: DONE

Add infrastructure for security group boundaries.

Model security groups for:

- load balancer
- ECS services
- RDS PostgreSQL
- Redis cache if enabled

Rules should express:

- public internet to ALB only
- ALB to service port only
- service to database only
- service to Redis only where enabled
- no public database/cache ingress

Implement either as a module or environment-level resources if clearer.

Document the intent.

Run `scripts/quality-gate.sh`.

Commit when complete.

---

## 006 — Add IAM module

Status: DONE

Create `infra/terraform/modules/iam/`.

Model:

- ECS task execution role
- ECS task role
- optional policies for reading secret references
- least-privilege intent
- separation between execution role and application task role

Do not include real secret ARNs.

Use placeholder variable-based secret ARNs.

Add README explaining:

- task role versus execution role
- why secrets are references, not values
- production review requirements

Wire into dev/prod environments.

Run `scripts/quality-gate.sh`.

Commit when complete.

---

## 007 — Add ECS service module

Status: DONE

Create `infra/terraform/modules/ecs-service/`.

Model:

- ECS cluster or accept cluster ID/ARN
- task definition
- service
- container definition
- CloudWatch log group
- ALB target group
- ALB listener rule or attachment pattern
- health checks
- CPU/memory variables
- desired count
- environment variables
- secret references
- autoscaling variables where practical

Use fake image names only.

Add module README.

Wire dev/prod examples for at least:

- `carbon-platform-api`
- `job-runner-platform`
- `multi-tenant-saas-api`

Do not copy application code.

Run `scripts/quality-gate.sh`.

Commit when complete.

---

## 008 — Add load balancer module

Status: DONE

Create `infra/terraform/modules/load-balancer/`.

Model:

- Application Load Balancer
- HTTP listener
- optional HTTPS listener variables, but no real cert ARN
- target group wiring pattern
- access logs as optional/placeholder if practical
- outputs used by ECS service module/environment

Add README explaining:

- health checks
- public edge
- HTTPS production requirement
- why database/cache stay private

Wire into dev/prod environments.

Run `scripts/quality-gate.sh`.

Commit when complete.

---

## 009 — Add RDS PostgreSQL module

Status: DONE

Create `infra/terraform/modules/rds-postgres/`.

Model:

- RDS PostgreSQL instance or cluster pattern
- subnet group
- private accessibility by default
- security group input
- backup retention variable
- deletion protection variable
- storage configuration variables
- monitoring-related variables where practical
- password/credentials via secret reference pattern, not committed value

If Terraform requires a password variable, mark it sensitive and only show placeholder references in examples.

Add README explaining:

- private database design
- backups
- deletion protection
- cost implications
- migration considerations
- production hardening gaps

Wire into dev/prod environments.

Run `scripts/quality-gate.sh`.

Commit when complete.

---

## 010 — Add Redis cache module

Status: DONE

Create `infra/terraform/modules/redis-cache/`.

Model:

- ElastiCache Redis/Valkey-style cache pattern
- subnet group
- private security group input
- enable/disable variable at environment level
- small dev-friendly configuration
- production variables for replicas/multi-AZ where practical

Add README explaining:

- optional cache use
- private access
- cost implications
- production hardening gaps

Wire into dev/prod environments with an enable flag.

Run `scripts/quality-gate.sh`.

Commit when complete.

---

## 011 — Add observability module

Status: DONE

Create `infra/terraform/modules/observability/`.

Model:

- CloudWatch dashboard
- alarms for ALB 5xx or unhealthy targets where practical
- ECS service CPU/memory alarms where practical
- RDS alarm examples where practical
- log group naming conventions
- outputs for dashboard name/ARN where practical

Add README explaining:

- logs
- metrics
- alarms
- dashboard
- production gaps such as paging/incident routing

Wire into dev/prod environments.

Run `scripts/quality-gate.sh`.

Commit when complete.

---

## 012 — Add secrets/reference pattern

Status: DONE

Add Terraform and docs for secret references.

Model one of:

- AWS Secrets Manager references
- SSM Parameter Store references

Do not create or store real secret values.

Document:

- secret values should be created outside this repo or via secure pipelines
- app receives secret references
- no committed secret values
- rotation considerations
- local placeholder examples only

Update environment examples and ECS service inputs.

Run `scripts/quality-gate.sh`.

Commit when complete.

---

## 013 — Add service examples for the three portfolio apps

Status: DONE

Add public-safe Terraform examples or variables that show how the infrastructure would deploy:

- `carbon-platform-api`
- `job-runner-platform`
- `multi-tenant-saas-api`

Use fake image names only.

For each service, document:

- expected health path
- environment variables as placeholders
- database/cache needs
- secret references
- metrics/logging expectations
- deployment notes

Do not copy application code.

Run `scripts/quality-gate.sh`.

Commit when complete.

---

## 014 — Add GitHub Actions validation CI

Status: DONE

Implement `.github/workflows/ci.yml`.

CI should run:

- shell syntax checks
- public-safety guardrails
- Terraform fmt
- Terraform init with `-backend=false`
- Terraform validate for environments
- no mutation command check
- no Terraform state check
- docs/link sanity checks if practical

CI must not run:

- `terraform apply`
- `terraform destroy`
- cloud CLI mutation commands

Use public-safe validation only.

Run `scripts/quality-gate.sh`.

Commit when complete.

---

## 015 — Add architecture docs and diagrams

Status: DONE

Create or complete:

- `docs/architecture.md`
- `docs/diagrams/aws-container-platform.md`

Docs should explain:

- VPC/subnet layout
- ALB/public edge
- ECS private service placement
- RDS private placement
- optional Redis private placement
- CloudWatch logs/metrics
- IAM roles
- secret references
- environment separation
- request flow
- deployment flow

Use text diagrams or Mermaid where practical.

Run `scripts/quality-gate.sh`.

Commit when complete.

---

## 016 — Add deployment guide

Status: DONE

Create `docs/deployment.md`.

Include:

- pre-deploy checklist
- required local tools
- how to run validation
- how to initialise Terraform manually
- how to review a plan
- manual apply warning
- service image update flow
- environment promotion approach
- migration considerations
- post-deploy checks

Make clear that apply is optional, manual, user-owned, and can incur cost.

Do not add scripts that apply infrastructure.

Run `scripts/quality-gate.sh`.

Commit when complete.

---

## 017 — Add rollback guide

Status: DONE

Create `docs/rollback.md`.

Include rollback strategies for:

- bad container image
- failing health checks
- failed ECS deployment
- bad environment variable/secret reference
- database migration issue
- RDS incident
- Redis/cache issue
- ALB/routing issue

Include:

- decision tree
- verification steps
- metrics/logs to check
- communication notes
- safety notes

Run `scripts/quality-gate.sh`.

Commit when complete.

---

## 018 — Add operations guide and runbook

Status: DONE

Create or complete:

- `docs/operations.md`
- `docs/runbook.md`

Cover:

- health checks
- logs
- metrics
- alarms
- incident triage
- RDS connectivity issue
- service crash loop
- high 5xx rate
- high latency
- database saturation
- Redis unavailable
- deployment stuck
- cost cleanup
- access review

Run `scripts/quality-gate.sh`.

Commit when complete.

---

## 019 — Add cost notes

Status: DONE

Create `docs/cost-notes.md`.

Cover:

- cost drivers
- NAT gateway cost implications
- RDS cost implications
- ALB cost implications
- ECS Fargate cost drivers
- CloudWatch log/metric costs
- Redis/ElastiCache costs
- dev versus prod trade-offs
- cleanup checklist
- how to avoid accidental spend

Do not claim exact current cloud prices unless clearly labelled as illustrative and manually verified.

Run `scripts/quality-gate.sh`.

Commit when complete.

---

## 020 — Add security guide

Status: TODO

Create `docs/security.md`.

Cover:

- no committed secrets
- no Terraform state in git
- IAM role separation
- least-privilege intent
- private database/cache
- public ALB boundary
- secret reference pattern
- CI validation-only posture
- manual apply warnings
- production hardening gaps
- access review checklist
- threat model summary

Run `scripts/quality-gate.sh`.

Commit when complete.

---

## 021 — Add review guide

Status: TODO

Create `docs/review-guide.md`.

This should help hiring reviewers inspect the repo quickly.

Include:

- suggested 10-minute review path
- suggested 30-minute review path
- important modules to inspect
- important docs to inspect
- what the project demonstrates
- what is intentionally out of scope
- how it complements the three backend repos

Run `scripts/quality-gate.sh`.

Commit when complete.

---

## 022 — Add ADRs

Status: TODO

Create ADRs:

- `docs/decisions/0001-aws-ecs-fargate-as-container-platform.md`
- `docs/decisions/0002-terraform-modules-and-environments.md`
- `docs/decisions/0003-private-database-and-cache.md`
- `docs/decisions/0004-secrets-are-references-not-values.md`
- `docs/decisions/0005-validation-only-ci.md`

Each ADR should include:

- status
- context
- decision
- consequences

Run `scripts/quality-gate.sh`.

Commit when complete.

---

## 023 — Final README polish

Status: TODO

Polish README so the first screen clearly sells the portfolio value.

README must include:

- concise headline
- portfolio framing
- public-safety constraints
- cloud-safety constraints
- implemented scope
- out-of-scope section
- requirements
- quick start validation
- repo structure
- architecture summary
- Terraform module summary
- environment summary
- CI/quality gate summary
- deployment/rollback docs links
- cost/security docs links
- suggested review path
- limitations

Run `scripts/quality-gate.sh`.

Commit when complete.

---

## 024 — Final autonomous review and completion marker

Status: TODO

Perform a final repository review.

Check:

- no employer/private details
- no real cloud account IDs
- no real secrets
- no Terraform state
- no real `.tfvars`
- no plan files
- no automated `terraform apply`
- no automated `terraform destroy`
- no cloud mutation CI
- Terraform fmt/validate coverage exists
- CI exists and is coherent
- docs match implemented Terraform
- modules have READMEs
- environments have examples
- cost notes exist
- rollback/runbook docs exist
- public portfolio framing is clear

Run full quality gate.

If everything is complete, set the top-level automation status to DONE.

Commit final review.
