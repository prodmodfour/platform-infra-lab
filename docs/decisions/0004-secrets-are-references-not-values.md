# 0004 — Secrets are references, not values

## Status

Accepted.

## Context

This repository is an independent public portfolio project. It must not contain credentials, API keys, database passwords, JWT signing keys, private endpoints, real cloud account details, or other secret values.

Terraform state and generated plans can expose sensitive values. Even placeholder examples can teach unsafe habits if they show raw secrets in Terraform variables, `.tfvars`, Markdown, scripts, or CI. At the same time, ECS services need a realistic pattern for receiving database connection details and application secrets at runtime.

## Decision

Represent secrets as references only.

The Secrets Manager reference module creates metadata-only `aws_secretsmanager_secret` resources for ECS secret injection. It deliberately does not create `aws_secretsmanager_secret_version` resources, does not accept `secret_string`, and does not generate secret values.

ECS task definitions receive environment-variable-name to secret-ARN mappings. The task execution role is granted access to the supplied secret reference ARNs so ECS can resolve values at task startup. The application task role remains separate and receives only explicitly reviewed permissions. RDS-managed master credentials are also surfaced as references, not raw password values.

Real secret values must be created outside this public repository or through a secure user-owned pipeline. Committed examples use public-safe names and placeholder metadata only.

## Consequences

This decision keeps the repository safe to publish and review. It also makes the intended secret lifecycle explicit: creation, rotation, emergency revocation, KMS ownership, audit review, and break-glass procedures belong outside this public lab.

The trade-off is that a manually provisioned copy of the lab is not a complete runnable application platform until the operator supplies real secret values through a secure process. Terraform validation can still run without those values, which is the intended portfolio behavior.

In real organizations, even secret names and ARNs can reveal sensitive structure. Users adapting this lab should avoid copying private secret paths, account identifiers, or internal naming into a public fork and should review IAM scopes, KMS key policies, rotation behavior, and rollback procedures before production use.
