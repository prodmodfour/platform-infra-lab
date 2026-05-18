#!/usr/bin/env bash
set -euo pipefail

# Lightweight Markdown link sanity checks for local repository links. External
# URLs are intentionally not fetched so CI remains deterministic and offline.

ROOT="${CHECK_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"

if ! command -v python3 >/dev/null 2>&1; then
  echo "WARNING: python3 is not installed; skipping Markdown link sanity checks." >&2
  exit 0
fi

CHECK_ROOT="$ROOT" python3 - <<'PY'
from __future__ import annotations

import os
import re
import sys
from pathlib import Path
from urllib.parse import unquote, urlparse

root = Path(os.environ["CHECK_ROOT"]).resolve()
failures: list[str] = []

# Inline Markdown links/images: [label](target) and ![alt](target).
LINK_RE = re.compile(r"!?\[[^\]]*\]\(([^)]+)\)")
SKIP_SCHEMES = {"http", "https", "mailto", "tel"}
PRUNED_DIRS = {".git", ".pi", ".terraform"}


def markdown_files() -> list[Path]:
    files: list[Path] = []
    for current_root, dirs, names in os.walk(root):
        dirs[:] = [d for d in dirs if d not in PRUNED_DIRS]
        for name in names:
            if name.endswith(".md"):
                files.append(Path(current_root) / name)
    return sorted(files)


def normalise_target(raw: str) -> str:
    target = raw.strip()
    if target.startswith("<") and ">" in target:
        target = target[1 : target.index(">")]
    # Drop optional Markdown title: [text](path.md "title"). Public repo links
    # should avoid spaces in paths, so splitting on whitespace is sufficient for
    # this sanity check.
    return target.split()[0] if target.split() else ""


def github_slug(heading: str) -> str:
    text = heading.strip().lower()
    text = re.sub(r"[`*_~]", "", text)
    text = re.sub(r"[^a-z0-9 _-]", "", text)
    text = re.sub(r"\s+", "-", text)
    text = re.sub(r"-+", "-", text)
    return text.strip("-")


def markdown_heading_slugs(path: Path) -> set[str]:
    slugs: set[str] = set()
    seen: dict[str, int] = {}
    try:
        lines = path.read_text(encoding="utf-8").splitlines()
    except UnicodeDecodeError:
        lines = path.read_text(errors="ignore").splitlines()

    for line in lines:
        match = re.match(r"^(#{1,6})\s+(.+?)\s*#*$", line)
        if not match:
            continue
        base = github_slug(match.group(2))
        if not base:
            continue
        count = seen.get(base, 0)
        seen[base] = count + 1
        slugs.add(base if count == 0 else f"{base}-{count}")
    return slugs


slug_cache: dict[Path, set[str]] = {}

for md_file in markdown_files():
    rel_file = md_file.relative_to(root)
    try:
        text = md_file.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        text = md_file.read_text(errors="ignore")

    for raw_target in LINK_RE.findall(text):
        target = normalise_target(raw_target)
        if not target:
            continue

        parsed = urlparse(target)
        if parsed.scheme in SKIP_SCHEMES or target.startswith("#"):
            target_path = md_file
            fragment = parsed.fragment or target[1:]
        elif parsed.scheme:
            continue
        else:
            without_fragment = target.split("#", 1)[0]
            fragment = target.split("#", 1)[1] if "#" in target else ""
            target_path = (md_file.parent / unquote(without_fragment)).resolve()

        try:
            target_path.relative_to(root)
        except ValueError:
            failures.append(f"{rel_file}: link escapes repository: {raw_target}")
            continue

        if not target_path.exists():
            failures.append(f"{rel_file}: missing local link target: {raw_target}")
            continue

        if fragment and target_path.is_file() and target_path.suffix == ".md":
            slugs = slug_cache.setdefault(target_path, markdown_heading_slugs(target_path))
            expected = unquote(fragment).lower()
            if expected not in slugs:
                failures.append(
                    f"{rel_file}: missing heading '#{fragment}' in "
                    f"{target_path.relative_to(root)}"
                )

if failures:
    print("Markdown link sanity checks failed:", file=sys.stderr)
    for failure in failures:
        print(f"ERROR: {failure}", file=sys.stderr)
    sys.exit(1)

print("Markdown link sanity checks passed.")
PY
