# Deployment

Placeholder for deployment guidance.

This project does not provide automatic cloud deployment. Future instructions will focus on validation, reviewable Terraform plans, and optional manual provisioning steps that are user-owned and can incur cloud cost.

Current ECS service examples use fake images and are wired to a public ALB HTTP listener with path-based listener rules. Per-service health paths, placeholder environment variables, database/cache needs, secret references, metrics/logging expectations, and deployment notes are documented in `docs/service-examples.md` and exposed through the Terraform `service_example_catalog` output. The Secrets Manager reference module creates metadata-only secret containers and passes ARNs into ECS task definitions, but real secret values must be created outside this repo or by a secure user-owned pipeline before any real service could start successfully. The RDS PostgreSQL example is private-only, uses RDS-managed Secrets Manager master credentials, and does not store database password values in Terraform examples. The Redis/Valkey cache example is private-only, optional, disabled in dev by default, enabled in prod to show failover/Multi-AZ intent, and does not store Redis AUTH token values. The CloudWatch observability example creates a dashboard and alarms but leaves alarm action lists empty until a user-owned environment supplies reviewed routing ARNs outside this repo. HTTPS remains optional and disabled in committed examples because real certificate ARNs do not belong in this repo. Do not treat the current Terraform as a one-click deployable production stack.

CI and local scripts must remain validation-only.
