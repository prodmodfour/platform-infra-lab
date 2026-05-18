# Documentation

This directory contains public-safe documentation for the `platform-infra-lab` AWS/Terraform portfolio project.

Detailed guides will be completed as the Terraform modules and environments are added. Current files are intentionally public-safe and evolve ticket-by-ticket without exposing private systems, credentials, real account IDs, or non-public architecture.

Document set:

- `architecture.md` — AWS container platform architecture, environment separation, request flow, and deployment flow.
- `diagrams/aws-container-platform.md` — public-safe text/Mermaid diagrams for the VPC, ALB, ECS, data, observability, and deployment-flow patterns.
- `deployment.md` — validation-first deployment checklist and manual review guidance.
- `rollback.md` — rollback strategies for service and infrastructure changes.
- `operations.md` and `runbook.md` — operational checks, observability usage, incident triage, and step-by-step response playbooks.
- `cost-notes.md` — qualitative cost drivers and cleanup guidance.
- `security.md` — public-safety, IAM, network, and secret-reference posture.
- `secrets.md` — Secrets Manager reference pattern without committed values.
- `service-examples.md` — public-safe ECS service examples for the three portfolio apps.
- `review-guide.md` — suggested path for portfolio reviewers.
- `decisions/` — architecture decision records.
- `diagrams/` — public-safe text or Mermaid diagrams.
