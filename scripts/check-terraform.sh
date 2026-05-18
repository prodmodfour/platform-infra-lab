#!/usr/bin/env bash
set -euo pipefail

# Terraform validation guardrail. Local runs warn and skip if Terraform is not
# installed; CI will install Terraform in a later ticket. When Terraform is
# available, the script checks formatting and validates every environment that
# contains .tf files without configuring a real backend.

ROOT="${CHECK_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
TERRAFORM_ROOT="$ROOT/infra/terraform"
ENVIRONMENTS_DIR="$TERRAFORM_ROOT/environments"

if ! command -v terraform >/dev/null 2>&1; then
  echo "WARNING: Terraform is not installed; skipping terraform fmt/init/validate locally." >&2
  echo "CI will install Terraform when validation CI is added."
  exit 0
fi

if [[ ! -d "$TERRAFORM_ROOT" ]]; then
  echo "No Terraform root found at $TERRAFORM_ROOT; skipping."
  exit 0
fi

echo "Running terraform fmt -recursive -check..."
terraform -chdir="$TERRAFORM_ROOT" fmt -recursive -check

if [[ ! -d "$ENVIRONMENTS_DIR" ]]; then
  echo "No Terraform environments directory found; skipping init/validate."
  exit 0
fi

mapfile -t environments < <(
  find "$ENVIRONMENTS_DIR" -mindepth 1 -maxdepth 1 -type d | sort
)

validated_any=0
for env_dir in "${environments[@]}"; do
  if ! find "$env_dir" -maxdepth 1 -type f -name '*.tf' | grep -q .; then
    echo "Skipping $(basename "$env_dir") environment; no .tf files yet."
    continue
  fi

  validated_any=1
  rel_env="${env_dir#"$TERRAFORM_ROOT"/}"
  tmp_dir="$(mktemp -d)"
  trap 'rm -rf "$tmp_dir"' EXIT
  mkdir -p "$tmp_dir/terraform"

  # Validate from a temporary copy so terraform init cannot dirty the working tree
  # with .terraform data or dependency lock files.
  tar --exclude='.terraform' --exclude='.terraform.lock.hcl' -cf - -C "$TERRAFORM_ROOT" . \
    | tar -xf - -C "$tmp_dir/terraform"

  tmp_env_dir="$tmp_dir/terraform/$rel_env"
  echo "Running terraform init -backend=false for $rel_env..."
  terraform -chdir="$tmp_env_dir" init -backend=false -input=false -no-color

  echo "Running terraform validate for $rel_env..."
  terraform -chdir="$tmp_env_dir" validate -no-color

  rm -rf "$tmp_dir"
  trap - EXIT
done

if (( validated_any == 0 )); then
  echo "No Terraform environments with .tf files found; init/validate skipped."
fi

echo "Terraform validation passed."
