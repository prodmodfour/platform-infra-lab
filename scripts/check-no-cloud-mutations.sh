#!/usr/bin/env bash
set -euo pipefail

# Validation-only guardrail. This scans automation entry points for commands that
# would mutate cloud infrastructure. Documentation may discuss manual commands,
# but scripts and CI must not run them automatically.

ROOT="${CHECK_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
FAILURES=0

shopt -s extglob

fail() {
  echo "ERROR: $*" >&2
  FAILURES=1
}

candidate_files() {
  local path

  if [[ -d "$ROOT/scripts" ]]; then
    find "$ROOT/scripts" -type f -print0
  fi

  if [[ -d "$ROOT/.github/workflows" ]]; then
    find "$ROOT/.github/workflows" -type f \( -name '*.yml' -o -name '*.yaml' \) -print0
  fi

  for path in \
    "$ROOT/Makefile" \
    "$ROOT/makefile" \
    "$ROOT/GNUmakefile" \
    "$ROOT/Taskfile.yml" \
    "$ROOT/Taskfile.yaml" \
    "$ROOT/justfile" \
    "$ROOT/Justfile" \
    "$ROOT/package.json"; do
    [[ -f "$path" ]] && printf '%s\0' "$path"
  done
}

normalise_line() {
  local line="$1"
  local package_script_re='^"[^"]+"[[:space:]]*:[[:space:]]*"(.+)"[,]?$'

  # Trim leading/trailing whitespace.
  line="${line##+([[:space:]])}"
  line="${line%%+([[:space:]])}"

  # Ignore obvious comments and empty lines.
  [[ -z "$line" || "$line" == \#* ]] && return 1

  # Strip YAML list markers used in workflow steps.
  while [[ "$line" =~ ^-[[:space:]]+(.+)$ ]]; do
    line="${BASH_REMATCH[1]}"
  done

  # Strip common GitHub Actions single-line run prefix.
  if [[ "$line" =~ ^run:[[:space:]]+(.+)$ ]]; then
    line="${BASH_REMATCH[1]}"
  fi

  # Strip simple package.json script prefixes: "deploy": "command".
  if [[ $line =~ $package_script_re ]]; then
    line="${BASH_REMATCH[1]}"
  fi

  printf '%s\n' "$line"
}

is_mutating_line() {
  local line="$1"
  local command_prefix='(^|[;&|][[:space:]]*)(if[[:space:]]+|then[[:space:]]+|do[[:space:]]+)?(sudo[[:space:]]+|time[[:space:]]+|timeout[[:space:]]+[0-9]+[[:space:]]+|env[[:space:]]+([^;&|[:space:]]+=[^;&|[:space:]]+[[:space:]]+)*)?'
  local terraform_opts='(-[A-Za-z0-9_=./:-]+[[:space:]]+)*'
  local aws_opts='(--[A-Za-z0-9-]+([=[:space:]][^;&|[:space:]]+)?[[:space:]]+)*'

  # Terraform operations that create, change, destroy, or import remote resources.
  if [[ "$line" =~ ${command_prefix}terraform[[:space:]]+${terraform_opts}(apply|destroy|import)([[:space:]]|$) ]]; then
    return 0
  fi

  # Terragrunt wraps Terraform and must follow the same no-mutation policy.
  if [[ "$line" =~ ${command_prefix}terragrunt[[:space:]]+${terraform_opts}(apply|destroy|import)([[:space:]]|$) ]]; then
    return 0
  fi

  # AWS CLI resource mutation verbs. Read-only commands such as sts get-caller-identity
  # are intentionally not matched.
  if [[ "$line" =~ ${command_prefix}aws[[:space:]]+${aws_opts}[a-z0-9-]+[[:space:]]+(create|update|delete|put|modify|deploy|start|stop|run|terminate|reboot|attach|detach|import|execute)[a-z0-9-]*([[:space:]]|$) ]]; then
    return 0
  fi

  # High-risk S3 commands can upload/delete/move objects and are treated as mutation.
  if [[ "$line" =~ ${command_prefix}aws[[:space:]]+${aws_opts}s3[[:space:]]+(cp|sync|rm|mv|mb|rb)([[:space:]]|$) ]]; then
    return 0
  fi

  # Common deploy CLIs that mutate cloud infrastructure.
  if [[ "$line" =~ ${command_prefix}(sam|serverless|sls|cdk)[[:space:]]+deploy([[:space:]]|$) ]]; then
    return 0
  fi

  return 1
}

while IFS= read -r -d '' file; do
  rel="${file#"$ROOT"/}"
  line_number=0
  while IFS= read -r raw_line || [[ -n "$raw_line" ]]; do
    line_number=$((line_number + 1))
    if ! line="$(normalise_line "$raw_line")"; then
      continue
    fi
    if is_mutating_line "$line"; then
      fail "cloud mutation command found in $rel:$line_number: $raw_line"
    fi
  done < "$file"
done < <(candidate_files)

if (( FAILURES > 0 )); then
  echo "Cloud mutation guardrail failed." >&2
  exit 1
fi

echo "Cloud mutation guardrail passed."
