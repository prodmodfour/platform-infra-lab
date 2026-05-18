# Terraform infrastructure

This directory contains the Terraform design for the public-safe AWS platform lab. It is organised for reviewability: reusable modules live under `modules/`, and deployable environment roots live under `environments/`.

The repository is intentionally validation-first. Terraform code should be easy to format, initialise with backends disabled, and validate in CI without requiring cloud credentials. Provisioning is not automated from this repo.

## Safety rules

- Do not commit real backend configuration. Use `backend.example.tf` for public-safe examples only.
- Do not commit real variable files. Use `terraform.tfvars.example` for placeholders and documentation.
- Never commit Terraform state, state backups, generated plans, lock-table data, credentials, SSH keys, kubeconfigs, or local `.env` files.
- CI and scripts must stay validation-only: format, lint, initialise with `-backend=false`, and validate.
- Any manual apply is optional, user-owned, must happen outside automation, and can incur cloud cost.
- Use only public-safe placeholder names, fake image names, and generic service names.

## Layout

```text
infra/terraform/
├── README.md
├── modules/
│   ├── README.md
│   ├── iam/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   ├── network/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   └── security-groups/
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── README.md
└── environments/
    ├── README.md
    ├── dev/
    │   ├── providers.tf
    │   ├── main.tf
    │   ├── variables.tf
    │   ├── outputs.tf
    │   ├── backend.example.tf
    │   ├── terraform.tfvars.example
    │   └── README.md
    └── prod/
        ├── providers.tf
        ├── main.tf
        ├── variables.tf
        ├── outputs.tf
        ├── backend.example.tf
        ├── terraform.tfvars.example
        └── README.md
```

The `dev` and `prod` environment roots now both wire the shared `network`, `security-groups`, and `iam` modules. Future tickets add the remaining modules and continue wiring the same module set into both environments.

## Naming guidance

Use predictable, public-safe names that make plans easy to review.

Recommended pattern:

```text
<project>-<environment>-<component>
```

Examples:

- `platform-infra-lab-dev-vpc`
- `platform-infra-lab-prod-ecs-cluster`
- `platform-infra-lab-dev-carbon-platform-api`

Conventions:

- Use lowercase kebab-case for AWS resource names where the service supports it.
- Keep names generic and portfolio-safe; do not include employer names, private system names, or real account identifiers.
- Keep service identifiers aligned with the demo services: `carbon-platform-api`, `job-runner-platform`, and `multi-tenant-saas-api`.
- Prefer explicit resource names over opaque generated strings when that improves plan review.

## Tagging guidance

Every taggable resource should receive a common tag set from the environment root and any resource-specific tags required by the module.

Recommended common tags:

```hcl
common_tags = {
  Project     = "platform-infra-lab"
  Environment = "dev"
  ManagedBy   = "terraform"
  Repository  = "platform-infra-lab"
  Purpose     = "public-portfolio-demo"
}
```

Tagging conventions:

- Environment roots define `common_tags`; modules accept tags as input.
- Modules should merge common tags with module-specific tags rather than replacing them.
- Do not encode secrets, account IDs, personal data, private cost-centre names, or internal hostnames in tags.
- Tags should support review, ownership, cleanup, and cost-awareness without exposing private information.

## Module conventions

Reusable modules should be small, explicit, and easy to review.

Expected module files:

- `main.tf` — resources and data sources.
- `variables.tf` — typed inputs with descriptions.
- `outputs.tf` — outputs used by environments or other modules.
- `README.md` — purpose, resources, inputs, outputs, security notes, cost notes, and production gaps.

Interface expectations:

- Prefer explicit variables over implicit naming or hidden defaults.
- Accept `name_prefix`, `environment`, and `common_tags` where useful.
- Accept IDs/ARNs for dependencies rather than reaching across module boundaries with data sources unless there is a clear reason.
- Mark sensitive inputs as `sensitive = true` when Terraform must receive a sensitive value.
- Prefer secret references, such as Secrets Manager or SSM Parameter Store ARNs/names, instead of secret values.
- Output only what downstream modules need; avoid broad outputs that expose unnecessary details.
- Do not configure providers or backends inside reusable modules.

Implemented modules:

- `modules/network` — VPC, public/private subnets, internet gateway, route tables, and optional NAT gateway.
- `modules/security-groups` — public ALB, private ECS service, private PostgreSQL, and optional private Redis security group boundaries.
- `modules/iam` — ECS task execution role, application task role, and optional secret-reference read policies.

See `modules/README.md` for detailed module interface conventions.

## Environment conventions

Each environment root should assemble the same module set with environment-specific inputs.

Expected environment files:

- `providers.tf`
- `main.tf`
- `variables.tf`
- `outputs.tf`
- `backend.example.tf`
- `terraform.tfvars.example`
- `README.md`

Environment expectations:

- `dev` should use smaller, cost-aware defaults for demonstration.
- `prod` should show production-intent settings such as stronger retention, deletion protection, and higher availability where practical.
- Environment differences should be visible in variables and example values, not hidden in module internals.
- Real secrets, account IDs, backend bucket names, and local operator settings must not be committed.

See `environments/README.md` for detailed environment conventions.

## Backend configuration guidance

Commit only public-safe backend examples named `backend.example.tf`. Do not commit a real `backend.tf` or any file containing actual state bucket names, lock table names, account IDs, or operator-specific paths.

A backend example may show the shape of remote state configuration with placeholder values, but real values belong outside this repository or in a local file that is never committed.

Validation must initialise Terraform with backend access disabled:

```bash
terraform init -backend=false
```

This keeps local and CI validation independent of user-owned cloud accounts and avoids accidental state access.

## Validation

Run the repository quality gate before opening or committing changes:

```bash
bash scripts/quality-gate.sh
```

The gate checks shell syntax, public-safety rules, forbidden state/plan/variable files, forbidden automation mutations, Terraform formatting, and Terraform validation when Terraform is installed. Later CI remains validation-only and must not provision or destroy infrastructure.
