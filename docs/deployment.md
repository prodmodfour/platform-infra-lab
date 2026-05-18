# Deployment

Placeholder for deployment guidance.

This project does not provide automatic cloud deployment. Future instructions will focus on validation, reviewable Terraform plans, and optional manual provisioning steps that are user-owned and can incur cloud cost.

Current ECS service examples use fake images and are wired to a public ALB HTTP listener with path-based listener rules. The RDS PostgreSQL example is private-only, uses RDS-managed Secrets Manager master credentials, and does not store database password values in Terraform examples. The Redis/Valkey cache example is private-only, optional, disabled in dev by default, enabled in prod to show failover/Multi-AZ intent, and does not store Redis AUTH token values. HTTPS remains optional and disabled in committed examples because real certificate ARNs do not belong in this repo. Do not treat the current Terraform as a one-click deployable production stack.

CI and local scripts must remain validation-only.
