#!/usr/bin/env bash
set -euo pipefail

# Public-safety guardrail for files that should never enter this public portfolio repo.
# The script scans the working tree (not only git-tracked files) while pruning local
# tool/cache directories that are not repository content.

ROOT="${CHECK_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
FAILURES=0

fail() {
  echo "ERROR: $*" >&2
  FAILURES=1
}

is_allowed_account_id() {
  case "$1" in
    000000000000|111111111111|123456789012|999999999999)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

is_text_file() {
  local file="$1"
  [[ -f "$file" ]] || return 1
  grep -Iq . "$file"
}

scan_file_name() {
  local path="$1"
  local rel="$2"
  local base
  base="$(basename "$path")"

  case "$base" in
    .env|.env.*)
      if [[ "$base" != ".env.example" ]]; then
        fail "environment file is not public-safe: $rel"
      fi
      ;;
    *.pem|*.key|*.p12|*.pfx|id_rsa|id_rsa.*|id_ed25519|id_ed25519.*)
      fail "private key or certificate-looking file is not public-safe: $rel"
      ;;
    credentials|credentials.csv|aws_credentials|aws-credentials|aws_credentials.json|.aws_credentials)
      fail "AWS credential-looking file is not public-safe: $rel"
      ;;
  esac

  case "$rel" in
    .aws|.aws/*|*/.aws|*/.aws/*)
      fail "AWS credential/config directory is not public-safe: $rel"
      ;;
  esac
}

scan_file_contents() {
  local path="$1"
  local rel="$2"
  local ids id
  local private_key_pattern
  private_key_pattern='BEGIN [A-Z ]*PRIVATE KEY|BEGIN OPENSSH '"PRIVATE KEY"

  is_text_file "$path" || return 0

  if grep -InE 'AKIA[0-9A-Z]{16}|ASIA[0-9A-Z]{16}' -- "$path" >/dev/null; then
    fail "AWS access-key-looking token found in: $rel"
    grep -InE 'AKIA[0-9A-Z]{16}|ASIA[0-9A-Z]{16}' -- "$path" >&2 || true
  fi

  if grep -InE 'aws_(access_key_id|secret_access_key|session_token)[[:space:]]*=' -- "$path" >/dev/null; then
    fail "AWS credential assignment found in: $rel"
    grep -InE 'aws_(access_key_id|secret_access_key|session_token)[[:space:]]*=' -- "$path" >&2 || true
  fi

  if grep -InE "$private_key_pattern" -- "$path" >/dev/null; then
    fail "private key material found in: $rel"
    grep -InE "$private_key_pattern" -- "$path" >&2 || true
  fi

  ids="$(grep -Eo '(^|[^0-9])[0-9]{12}([^0-9]|$)' -- "$path" | grep -Eo '[0-9]{12}' || true)"
  if [[ -n "$ids" ]]; then
    while IFS= read -r id; do
      [[ -n "$id" ]] || continue
      if ! is_allowed_account_id "$id"; then
        fail "real-looking 12-digit cloud account ID found in $rel: $id"
      fi
    done <<< "$ids"
  fi
}

while IFS= read -r -d '' entry; do
  rel="${entry#"$ROOT"/}"
  if [[ -d "$entry" ]]; then
    case "$(basename "$entry")" in
      .aws)
        fail "AWS credential/config directory is not public-safe: $rel"
        ;;
    esac
    continue
  fi

  scan_file_name "$entry" "$rel"
  scan_file_contents "$entry" "$rel"
done < <(
  find "$ROOT" \
    \( -path "$ROOT/.git" -o -path "$ROOT/.pi" -o -name .terraform \) -prune \
    -o \( -type f -o -type d \) -print0
)

if (( FAILURES > 0 )); then
  echo "Public-safety guardrail failed." >&2
  exit 1
fi

echo "Public-safety guardrail passed."
