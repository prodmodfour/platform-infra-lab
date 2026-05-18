#!/usr/bin/env bash
set -euo pipefail

# Guard against committing or even keeping generated Terraform/private runtime files
# in the repository working tree. Example files are allowed when explicitly named
# with .example suffixes.

ROOT="${CHECK_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
FAILURES=0

fail() {
  echo "ERROR: $*" >&2
  FAILURES=1
}

is_allowed_tfvars_example() {
  local base="$1"
  case "$base" in
    *.tfvars.example|*.tfvars.json.example)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

while IFS= read -r -d '' file; do
  rel="${file#"$ROOT"/}"
  base="$(basename "$file")"

  case "$base" in
    *.tfstate|*.tfstate.*)
      fail "Terraform state file found: $rel"
      ;;
    *.tfplan|*.plan|tfplan)
      fail "generated Terraform plan file found: $rel"
      ;;
    *.tfvars|*.tfvars.json)
      if ! is_allowed_tfvars_example "$base"; then
        fail "real Terraform variable file found (commit .example files only): $rel"
      fi
      ;;
    .env|.env.*)
      if [[ "$base" != ".env.example" ]]; then
        fail "environment file found (do not commit local secrets): $rel"
      fi
      ;;
  esac
done < <(
  find "$ROOT" \
    \( -path "$ROOT/.git" -o -path "$ROOT/.pi" -o -name .terraform \) -prune \
    -o -type f -print0
)

if (( FAILURES > 0 )); then
  echo "Terraform state/secret-file guardrail failed." >&2
  exit 1
fi

echo "Terraform state/secret-file guardrail passed."
