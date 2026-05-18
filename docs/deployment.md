# Deployment

Placeholder for deployment guidance.

This project does not provide automatic cloud deployment. Future instructions will focus on validation, reviewable Terraform plans, and optional manual provisioning steps that are user-owned and can incur cloud cost.

Current ECS service examples use fake images and are wired to a public ALB HTTP listener with path-based listener rules. HTTPS remains optional and disabled in committed examples because real certificate ARNs do not belong in this repo. Do not treat the current Terraform as a one-click deployable production stack.

CI and local scripts must remain validation-only.
