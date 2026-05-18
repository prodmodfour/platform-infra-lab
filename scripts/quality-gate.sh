#!/usr/bin/env bash
set -euo pipefail

require_path() {
  local path="$1"
  if [[ ! -e "$path" ]]; then
    echo "Missing required bootstrap path: $path" >&2
    exit 1
  fi
}

echo "== bootstrap structure checks =="
required_paths=(
  README.md
  .gitignore
  AGENTS.md
  BUILD_TICKETS.md
  BUILD_NOTES.md
  scripts
  docs
  docs/decisions
  docs/diagrams
  infra
  infra/terraform
  infra/terraform/modules
  infra/terraform/environments
)

for path in "${required_paths[@]}"; do
  require_path "$path"
done

echo "== README framing checks =="
grep -qi "independent public portfolio" README.md
grep -qi "AWS/Terraform" README.md
grep -qi "no automatic cloud deployment" README.md
grep -qi "no committed secrets" README.md
grep -qi "No Terraform state" README.md
grep -qi "manual apply.*can incur" README.md
grep -qi "backend/platform/SRE" README.md

echo "== shell syntax checks =="
for script in scripts/*.sh; do
  [[ -e "$script" ]] || continue
  bash -n "$script"
done

if [[ -f scripts/check-public-safety.sh ]]; then
  echo "== public-safety guardrail =="
  bash scripts/check-public-safety.sh
fi

if [[ -f scripts/check-no-terraform-state.sh ]]; then
  echo "== Terraform state guardrail =="
  bash scripts/check-no-terraform-state.sh
fi

if [[ -f scripts/check-no-cloud-mutations.sh ]]; then
  echo "== cloud mutation guardrail =="
  bash scripts/check-no-cloud-mutations.sh
fi

if [[ -f scripts/check-terraform.sh ]]; then
  echo "== Terraform validation =="
  bash scripts/check-terraform.sh
fi

echo "== quality gate passed =="
