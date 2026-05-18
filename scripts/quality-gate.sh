#!/usr/bin/env bash
set -euo pipefail

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

