#!/usr/bin/env bash
set -euo pipefail

# Lightweight self-checks for guardrail scripts. The tests create a temporary
# fixture outside the repository and verify that representative unsafe files and
# commands fail while a clean fixture passes.

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
TMP_ROOT="$(mktemp -d)"
OUT_FILE="$TMP_ROOT/guardrail-test.out"
trap 'rm -rf "$TMP_ROOT"' EXIT

expect_pass() {
  local description="$1"
  shift
  if ! "$@" >"$OUT_FILE" 2>&1; then
    echo "ERROR: expected pass: $description" >&2
    cat "$OUT_FILE" >&2 || true
    exit 1
  fi
}

expect_fail() {
  local description="$1"
  shift
  if "$@" >"$OUT_FILE" 2>&1; then
    echo "ERROR: expected failure: $description" >&2
    exit 1
  fi
}

reset_fixture() {
  rm -rf "$TMP_ROOT/fixture"
  mkdir -p "$TMP_ROOT/fixture/scripts" "$TMP_ROOT/fixture/infra/terraform/environments/dev"
  printf '#!/usr/bin/env bash\nterraform validate\n' > "$TMP_ROOT/fixture/scripts/validate.sh"
  printf 'placeholder = true\n' > "$TMP_ROOT/fixture/infra/terraform/environments/dev/terraform.tfvars.example"
}

run_public_safety() {
  CHECK_ROOT="$TMP_ROOT/fixture" bash "$ROOT/scripts/check-public-safety.sh"
}

run_no_state() {
  CHECK_ROOT="$TMP_ROOT/fixture" bash "$ROOT/scripts/check-no-terraform-state.sh"
}

run_no_mutations() {
  CHECK_ROOT="$TMP_ROOT/fixture" bash "$ROOT/scripts/check-no-cloud-mutations.sh"
}

reset_fixture
expect_pass "clean public-safety fixture" run_public_safety
expect_pass "clean Terraform state fixture" run_no_state
expect_pass "clean cloud mutation fixture" run_no_mutations

reset_fixture
printf '{}\n' > "$TMP_ROOT/fixture/dev.tfstate"
expect_fail "Terraform state file" run_no_state

reset_fixture
printf 'example = "not for commit"\n' > "$TMP_ROOT/fixture/dev.tfvars"
expect_fail "non-example tfvars file" run_no_state

reset_fixture
printf 'LOCAL_ONLY=true\n' > "$TMP_ROOT/fixture/.env"
expect_fail "local environment file" run_public_safety

reset_fixture
bad_account_id="314159""265358"
printf 'account = "%s"\n' "$bad_account_id" > "$TMP_ROOT/fixture/account.txt"
expect_fail "real-looking account id" run_public_safety

reset_fixture
bad_key="AKIA$(printf '1%.0s' {1..16})"
printf 'aws_%s = %s\n' "access_key_id" "$bad_key" > "$TMP_ROOT/fixture/credentials.txt"
expect_fail "AWS credential-looking content" run_public_safety

reset_fixture
printf '#!/usr/bin/env bash\nterraform apply -auto-approve\n' > "$TMP_ROOT/fixture/scripts/deploy.sh"
expect_fail "terraform apply automation" run_no_mutations

reset_fixture
printf '#!/usr/bin/env bash\naws cloudformation deploy --template-file template.yml --stack-name demo\n' > "$TMP_ROOT/fixture/scripts/deploy.sh"
expect_fail "AWS deploy automation" run_no_mutations

echo "Guardrail self-tests passed."
