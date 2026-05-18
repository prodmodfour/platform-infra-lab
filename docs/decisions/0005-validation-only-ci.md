# 0005 — Validation-only CI

## Status

Accepted.

## Context

The project should be safe for public review and safe to run in pull requests. It should demonstrate infrastructure validation discipline without requiring cloud credentials, mutating AWS resources, or creating accidental cloud spend.

Automated provisioning would make the lab riskier: a workflow could create billable resources, alter user-owned infrastructure, expose state, or normalize unsafe habits for a public repository. The portfolio value comes from readable Terraform, guardrails, documentation, and operational design rather than from a live shared environment.

## Decision

Keep local automation and GitHub Actions validation-only.

The quality gate runs repository checks such as:

- shell syntax validation
- public-safety scans
- Terraform state, plan, and real variable-file guardrails
- cloud mutation command scans for automation entry points
- Markdown link sanity checks
- Terraform formatting checks
- Terraform backend-disabled initialisation and validation for each environment when Terraform is available

CI installs Terraform and runs the same validation-oriented quality gate. CI does not configure cloud credentials and must not run Terraform apply, destroy, import, cloud deployment commands, or destructive cloud CLI operations.

Manual plan review and manual provisioning may be documented only as optional, user-owned activities that can incur cost. No apply or destroy scripts are provided.

## Consequences

This decision reduces the risk of accidental cloud mutation, surprise billing, state leakage, and credential exposure. It keeps the repository suitable for public portfolio review and makes pull requests safe to validate without an AWS account.

Validation-only CI cannot prove every runtime behavior. It will not catch all AWS service quota issues, provider-side policy constraints, IAM permission gaps in a real account, image pull failures, DNS/TLS misconfiguration, secret value problems, or live health-check behavior. Those require separate user-owned plan review, controlled manual deployment, and operational testing if someone adapts the lab.

Any future automation entry point must preserve this posture. If new scripts, workflow steps, Make targets, or package scripts are added, they must remain validation-only and be covered by the cloud mutation guardrail.
