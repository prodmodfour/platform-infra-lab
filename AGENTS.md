# AGENTS.md

You are building `platform-infra-lab`, an independent public portfolio project.

The project demonstrates platform engineering and infrastructure-as-code through a public-safe Terraform lab for deploying containerised backend services.

## Portfolio purpose

This repo should make the maintainer look like an obvious backend/platform/SRE candidate.

It must demonstrate:

- infrastructure-as-code structure and reviewability
- Terraform module design
- AWS container platform architecture
- ECS/Fargate service deployment patterns
- load balancing and health checks
- PostgreSQL/RDS infrastructure patterns
- Redis/ElastiCache infrastructure patterns where appropriate
- secret-management patterns without real secrets
- IAM least-privilege thinking
- networking and security group design
- observability with logs, metrics, dashboards, and alarms
- deployment and rollback documentation
- cost-awareness documentation
- environment separation
- CI validation for infrastructure code
- public-safety and secret guardrails
- operational runbooks

## Public-safety constraints

This is an independent public portfolio project.

Do not add:

- employer code
- private data
- internal URLs or hostnames
- credentials or tokens
- real AWS account IDs
- real cloud resource names from private systems
- screenshots of private systems
- non-public architecture
- anything implying employer endorsement

Use only public-safe placeholder names, fake account IDs where needed, and generic demo service names.

## Cloud-safety constraints

This repo must not automatically deploy or mutate cloud infrastructure.

Do not add scripts or CI jobs that run:

- `terraform apply`
- `terraform destroy`
- `terraform import`
- `aws cloudformation deploy`
- cloud CLI mutation commands
- destructive cloud operations

Terraform plans may be documented, but automated workflows should validate and lint only.

Manual apply instructions may be documented only with clear warnings that they are optional, user-owned, and can incur cost.

Do not commit:

- Terraform state
- `.tfvars` files containing real values
- generated plan files
- cloud credentials
- SSH keys
- kubeconfig files
- `.env` files with secrets

## Primary technology direction

Use:

- Terraform for AWS infrastructure
- GitHub Actions for validation
- shell scripts for lightweight checks
- Markdown documentation
- public-safe diagrams
- optional policy-style guardrails

Prefer AWS as the primary provider.

Do not build another FastAPI application in this repo.

## Reference service model

The infrastructure should be generic enough to deploy containerised backend services such as:

- `carbon-platform-api`
- `job-runner-platform`
- `multi-tenant-saas-api`

Do not copy application code into this repository.

Use fake image names, for example:

```text
public.ecr.aws/example/carbon-platform-api:demo
public.ecr.aws/example/job-runner-platform:demo
public.ecr.aws/example/multi-tenant-saas-api:demo

The purpose is to show deployment patterns, not to run the apps here.

Target architecture

Build a reviewable AWS Terraform architecture around:

VPC
public and private subnets
security groups
Application Load Balancer
ECS/Fargate cluster
ECS services and task definitions
CloudWatch logs
RDS PostgreSQL
optional ElastiCache Redis
SSM Parameter Store or Secrets Manager references
IAM task roles and execution roles
health checks
autoscaling configuration where practical
alarms and dashboards where practical

Keep it public-safe and cost-aware.

Suggested repository structure

Use a structure like:

README.md
AGENTS.md
BUILD_TICKETS.md
BUILD_NOTES.md
scripts/
infra/
  terraform/
    modules/
      network/
      ecs-service/
      rds-postgres/
      redis-cache/
      observability/
      iam/
    environments/
      dev/
      prod/
docs/
  architecture.md
  deployment.md
  rollback.md
  operations.md
  runbook.md
  cost-notes.md
  security.md
  review-guide.md
  diagrams/
  decisions/
.github/
  workflows/
Terraform design rules

Use readable modules.

Do not overengineer.

Prefer explicit variables and outputs.

Every module should have:

main.tf
variables.tf
outputs.tf
README.md

Every environment should have:

main.tf
variables.tf
outputs.tf
providers.tf
backend.example.tf
terraform.tfvars.example
README.md

Do not include real backend configuration.

Use backend.example.tf for public-safe backend examples.

Use terraform.tfvars.example, not real .tfvars.

Terraform should validate without cloud credentials where possible.

Do not require terraform apply for the portfolio value.

AWS design expectations

Network module should model:

VPC
public subnets
private subnets
route table intent
security group boundaries

ECS service module should model:

ECS task definition
ECS service
container definition
ALB target group attachment
log group
health check configuration
environment variables and secret references
task execution role
task role

RDS module should model:

PostgreSQL instance or cluster pattern
private subnet group
security group rules
backup/retention variables
deletion protection variable
no public accessibility by default
password from secret reference only, not raw committed value

Redis module should model:

cache subnet group
private-only security group
minimal configuration
optional enable flag

Observability should model:

CloudWatch log groups
alarms for service health, CPU/memory, ALB errors, RDS health where practical
dashboard JSON or Terraform dashboard resource where practical
Documentation expectations

Maintain:

README.md
docs/architecture.md
docs/deployment.md
docs/rollback.md
docs/operations.md
docs/runbook.md
docs/cost-notes.md
docs/security.md
docs/review-guide.md
docs/decisions/

Include at least these ADRs:

docs/decisions/0001-aws-ecs-fargate-as-container-platform.md
docs/decisions/0002-terraform-modules-and-environments.md
docs/decisions/0003-private-database-and-cache.md
docs/decisions/0004-secrets-are-references-not-values.md
docs/decisions/0005-validation-only-ci.md

Each ADR should include:

status
context
decision
consequences
Security expectations

Document and model:

private database/cache access
no public RDS by default
no committed secrets
security group boundaries
IAM task role versus execution role
secret references rather than secret values
least-privilege intent
validation-only CI
no automatic apply/destroy
production hardening gaps
Operations expectations

Docs should cover:

deployment checklist
pre-deploy review
plan review
health checks
rollback path
failed deploy response
database migration considerations
log and metric checks
incident triage
cost cleanup
how to avoid accidental cloud spend
Cost-awareness expectations

Do not claim exact current cloud prices.

Costs change.

Use qualitative cost notes and clearly mark any example numbers as illustrative only if used.

Prefer:

cost drivers
ways to reduce cost
resources that continue billing
cleanup checklist
why optional apply can incur cost
Testing and validation expectations

Every meaningful ticket should add or update validation.

Use:

shell syntax checks
public-safety checks
no-secret checks
no-state-file checks
no-apply-command checks
Terraform fmt checks
Terraform validate checks where Terraform is available
CI validation for Terraform

If Terraform is unavailable locally, scripts may warn, but CI should install/use Terraform and validate the infrastructure.

Automation behaviour

When invoked by the build loop:

Read AGENTS.md, BUILD_TICKETS.md, and BUILD_NOTES.md.
Select the lowest-numbered TODO or IN_PROGRESS ticket.
Implement only that ticket.
Do not start future tickets.
Do not broaden scope.
Add/update validation.
Add/update docs if behaviour, setup, architecture, security posture, operations, cost notes, or limitations change.
Run scripts/quality-gate.sh.
Update BUILD_TICKETS.md.
Update BUILD_NOTES.md.
Commit the completed ticket with a conventional commit message.
Leave the working tree clean.

If blocked:

explain the blocker in BUILD_NOTES.md
mark the ticket BLOCKED if appropriate
do not mark it DONE
do not commit broken partial work
leave the working tree clean if possible
Commit style

Use conventional commits:

chore:
feat:
fix:
test:
docs:
refactor:
ci:

Examples:

feat: add ECS service Terraform module
docs: add rollback runbook
ci: validate Terraform environments
test: add public-safety guardrail checks
