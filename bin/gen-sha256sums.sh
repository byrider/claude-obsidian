#!/usr/bin/env bash
# gen-sha256sums.sh — regenerate the SHA256SUMS integrity manifest.
#
# The manifest lists every file that bin/install-kiro.sh downloads, so the
# installer can verify each file after download (audit S3). Run this from the
# repo root whenever any installed file changes, then commit SHA256SUMS:
#
#   bash bin/gen-sha256sums.sh && git add SHA256SUMS
#
# Keep FILES in sync with the download lists in bin/install-kiro.sh.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

FILES=(
  # Skills
  ".kiro/skills/wiki-setup/SKILL.md"
  ".kiro/skills/wiki-ingest/SKILL.md"
  ".kiro/skills/wiki-code-ingest/SKILL.md"
  ".kiro/skills/wiki-query/SKILL.md"
  ".kiro/skills/wiki-lint/SKILL.md"
  ".kiro/skills/wiki-save/SKILL.md"
  ".kiro/skills/wiki-autoresearch/SKILL.md"
  ".kiro/skills/wiki-session-harvest/SKILL.md"
  ".kiro/skills/wiki-think/SKILL.md"
  # Hooks
  ".kiro/hooks/hot-cache-on-save.kiro.hook"
  ".kiro/hooks/auto-commit-wiki.kiro.hook"
  ".kiro/hooks/session-context.kiro.hook"
  ".kiro/hooks/session-end-summary.kiro.hook"
  ".kiro/hooks/clear-stale-locks.kiro.hook"
  # Steering + README
  ".kiro/steering/obsidian-wiki.md"
  ".kiro/steering/shared-vault.md"
  ".kiro/README.md"
  # Scripts
  "scripts/wiki-lock.sh"
  "scripts/wiki-mode.py"
  "scripts/detect-transport.sh"
  "bin/setup-kiro-vault.sh"
  "bin/setup-mode.sh"
  # Templates
  "_templates/concept.md"
  "_templates/entity.md"
  "_templates/source.md"
  "_templates/question.md"
  "_templates/comparison.md"
)

if command -v sha256sum >/dev/null 2>&1; then
  HASH() { sha256sum "$1"; }
elif command -v shasum >/dev/null 2>&1; then
  HASH() { shasum -a 256 "$1"; }
else
  echo "ERROR: need sha256sum or shasum" >&2
  exit 1
fi

OUT="SHA256SUMS"
: > "$OUT"
missing=0
for f in "${FILES[@]}"; do
  if [ -f "$f" ]; then
    HASH "$f" >> "$OUT"
  else
    echo "WARN: missing file, not listed: $f" >&2
    missing=$((missing + 1))
  fi
done

echo "Wrote $OUT ($(wc -l < "$OUT") entries, ${missing} missing)."
