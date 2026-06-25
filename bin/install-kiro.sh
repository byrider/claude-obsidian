#!/usr/bin/env bash
# install-kiro.sh — Install claude-obsidian Kiro skills into any project or vault
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/byrider/claude-obsidian/kiro-port/bin/install-kiro.sh | bash
#
# Pin to a specific commit:
#   curl -fsSL https://raw.githubusercontent.com/byrider/claude-obsidian/kiro-port/bin/install-kiro.sh | bash -s -- --version=2fad8c5
#
# Or locally:
#   bash bin/install-kiro.sh [target-directory]
#   bash bin/install-kiro.sh --version=v1.0.0 [target-directory]
#
# Integrity:
#   By default every downloaded file is verified against the SHA256SUMS manifest
#   published at the same ref. A checksum mismatch aborts the install.
#     --no-verify   skip checksum verification (not recommended)
#     --strict      also fail if the manifest or a sha256 tool is unavailable
#
# What it does:
#   1. Downloads the .kiro/ directory (skills, hooks, steering)
#   2. Downloads supporting scripts (wiki-lock, wiki-mode, detect-transport, etc.)
#   3. Downloads templates and bin/setup-kiro-vault.sh
#   4. Verifies each file against SHA256SUMS (unless --no-verify)
#   5. Runs setup-kiro-vault.sh to configure Obsidian and wiki structure
#   6. Reports what was installed

set -euo pipefail

# --- Configuration ---
REPO_OWNER="byrider"
REPO_NAME="claude-obsidian"
BRANCH="kiro-port"

# Parse flags
TARGET_DIR=""
VERIFY=true
STRICT=false
for arg in "$@"; do
  case "$arg" in
    --version=*) BRANCH="${arg#--version=}" ;;
    --no-verify) VERIFY=false ;;
    --strict) STRICT=true ;;
    -*) echo "Unknown option: $arg"; exit 1 ;;
    *) TARGET_DIR="$arg" ;;
  esac
done

RAW_BASE="https://raw.githubusercontent.com/${REPO_OWNER}/${REPO_NAME}/${BRANCH}"

# --- Target directory ---
TARGET_DIR="${TARGET_DIR:-$(pwd)}"
TARGET_DIR="$(cd "$TARGET_DIR" 2>/dev/null && pwd || echo "$TARGET_DIR")"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  claude-obsidian: Kiro Skills Installer"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  Target: $TARGET_DIR"
echo ""

# --- Check prerequisites ---
if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
  echo "ERROR: curl or wget required. Install one and retry."
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "WARNING: python3 not found. Scripts (wiki-mode.py, boundary-score.py, retrieve.py) will not work."
  echo "         Install Python 3 and retry, or continue without script support."
  echo ""
fi

# --- Integrity verification (audit S3) ---
# Verify every downloaded file against a SHA256SUMS manifest fetched from the same
# ref. Catches partial downloads, CDN corruption, and in-transit tampering of
# individual files. Uses awk lookups (not bash-4 associative arrays) so it works
# on the macOS system bash 3.2. Regenerate the manifest with bin/gen-sha256sums.sh.
MANIFEST_FILE=""

sha256_of() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
  else
    echo ""
  fi
}

load_manifest() {
  $VERIFY || return 0
  MANIFEST_FILE="$(mktemp 2>/dev/null || echo "/tmp/sha256sums.$$")"
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "${RAW_BASE}/SHA256SUMS" -o "$MANIFEST_FILE" 2>/dev/null || MANIFEST_FILE=""
  else
    wget -q "${RAW_BASE}/SHA256SUMS" -O "$MANIFEST_FILE" 2>/dev/null || MANIFEST_FILE=""
  fi
  if [ -z "$MANIFEST_FILE" ] || [ ! -s "$MANIFEST_FILE" ]; then
    echo "  ! could not fetch SHA256SUMS manifest for ref '${BRANCH}'"
    if $STRICT; then echo "    (--strict) aborting."; exit 1; fi
    echo "    continuing WITHOUT checksum verification."
    MANIFEST_FILE=""
  fi
}

# verify_file <repo-relative-path> <local-dest>  ->  0 ok | 1 mismatch/hard-fail
verify_file() {
  $VERIFY || return 0
  [ -n "$MANIFEST_FILE" ] || return 0
  local repo_path="$1" dest="$2" expected actual
  expected="$(awk -v p="$repo_path" '{f=$2; sub(/^\*/,"",f); if (f==p){print $1; exit}}' "$MANIFEST_FILE")"
  if [ -z "$expected" ]; then
    echo "  ! no checksum listed for ${repo_path}"
    $STRICT && return 1 || return 0
  fi
  actual="$(sha256_of "$dest")"
  if [ -z "$actual" ]; then
    echo "  ! no sha256 tool (install sha256sum or shasum); cannot verify ${repo_path}"
    $STRICT && return 1 || return 0
  fi
  if [ "$expected" != "$actual" ]; then
    echo "  ✗ CHECKSUM MISMATCH: ${repo_path}"
    echo "      expected: ${expected}"
    echo "      actual:   ${actual}"
    return 1
  fi
  return 0
}

# Helper: download a repo file by its repo-relative path, then verify it.
# Returns: 0 ok | 1 download failed (404/network) | 2 checksum mismatch
download() {
  local repo_path="$1"
  local dest="$2"
  local url="${RAW_BASE}/${repo_path}"
  mkdir -p "$(dirname "$dest")"
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$url" -o "$dest" 2>/dev/null || return 1
  else
    wget -q "$url" -O "$dest" 2>/dev/null || return 1
  fi
  verify_file "$repo_path" "$dest" || return 2
  return 0
}

# Fetch the integrity manifest before downloading anything else.
load_manifest

# --- Step 1: Install .kiro/ directory ---
echo "[1/5] Installing Kiro skills..."

SKILLS=(
  "wiki-setup"
  "wiki-ingest"
  "wiki-code-ingest"
  "wiki-query"
  "wiki-lint"
  "wiki-save"
  "wiki-autoresearch"
  "wiki-session-harvest"
  "wiki-think"
)

for skill in "${SKILLS[@]}"; do
  if ! download ".kiro/skills/${skill}/SKILL.md" \
                "${TARGET_DIR}/.kiro/skills/${skill}/SKILL.md"; then
    echo "  ✗ failed to install or verify skill: ${skill}"; exit 1
  fi
done
echo "  ✓ ${#SKILLS[@]} skills installed"

# --- Step 2: Install hooks ---
echo ""
echo "[2/5] Installing Kiro hooks..."

HOOKS=(
  "hot-cache-on-save"
  "auto-commit-wiki"
  "session-context"
  "session-end-summary"
  "clear-stale-locks"
)

for hook in "${HOOKS[@]}"; do
  if ! download ".kiro/hooks/${hook}.kiro.hook" \
                "${TARGET_DIR}/.kiro/hooks/${hook}.kiro.hook"; then
    echo "  ✗ failed to install or verify hook: ${hook}"; exit 1
  fi
done
echo "  ✓ ${#HOOKS[@]} hooks installed"

# --- Step 3: Install steering ---
echo ""
echo "[3/5] Installing steering files..."
for steer in "obsidian-wiki.md" "shared-vault.md"; do
  if ! download ".kiro/steering/${steer}" "${TARGET_DIR}/.kiro/steering/${steer}"; then
    echo "  ✗ failed to install or verify steering: ${steer}"; exit 1
  fi
done
if ! download ".kiro/README.md" "${TARGET_DIR}/.kiro/README.md"; then
  echo "  ✗ failed to install or verify .kiro/README.md"; exit 1
fi
echo "  ✓ Steering (2) + README installed"

# --- Step 4: Install supporting scripts ---
echo ""
echo "[4/5] Installing supporting scripts..."

SCRIPTS=(
  "scripts/wiki-lock.sh"
  "scripts/wiki-mode.py"
  "scripts/detect-transport.sh"
  "bin/setup-kiro-vault.sh"
  "bin/setup-mode.sh"
)

SCRIPT_OK=0
SCRIPT_SKIP=0
for script in "${SCRIPTS[@]}"; do
  if download "${script}" "${TARGET_DIR}/${script}"; then rc=0; else rc=$?; fi
  if [ "$rc" -eq 0 ]; then
    chmod +x "${TARGET_DIR}/${script}" 2>/dev/null || true
    SCRIPT_OK=$((SCRIPT_OK + 1))
  elif [ "$rc" -eq 2 ]; then
    echo "  ✗ checksum mismatch: ${script}"; exit 1
  else
    SCRIPT_SKIP=$((SCRIPT_SKIP + 1))
  fi
done
echo "  ✓ ${SCRIPT_OK} scripts installed (${SCRIPT_SKIP} skipped/unavailable)"

# --- Step 5: Install templates ---
echo ""
echo "[5/5] Installing templates..."

TEMPLATES=(
  "_templates/concept.md"
  "_templates/entity.md"
  "_templates/source.md"
  "_templates/question.md"
  "_templates/comparison.md"
)

TPL_OK=0
for tpl in "${TEMPLATES[@]}"; do
  if download "${tpl}" "${TARGET_DIR}/${tpl}"; then rc=0; else rc=$?; fi
  if [ "$rc" -eq 0 ]; then
    TPL_OK=$((TPL_OK + 1))
  elif [ "$rc" -eq 2 ]; then
    echo "  ✗ checksum mismatch: ${tpl}"; exit 1
  fi
done
echo "  ✓ ${TPL_OK} templates installed"

# --- Run setup ---
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ -x "${TARGET_DIR}/bin/setup-kiro-vault.sh" ]; then
  echo "Running vault setup..."
  echo ""
  bash "${TARGET_DIR}/bin/setup-kiro-vault.sh"
else
  echo "  Setup script not available. Run manually:"
  echo "    cd ${TARGET_DIR} && bash bin/setup-kiro-vault.sh"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Installation Complete"
echo ""
echo "  Installed to: ${TARGET_DIR}/.kiro/"
echo ""
echo "  Next steps:"
echo "    1. Open ${TARGET_DIR} in Obsidian"
echo "    2. Open Kiro in the same directory"
echo "    3. Say '/wiki' to start"
echo ""
echo "  To uninstall:"
echo "    rm -rf ${TARGET_DIR}/.kiro/skills/wiki-*"
echo "    rm -rf ${TARGET_DIR}/.kiro/hooks/*.kiro.hook"
echo "    rm -f  ${TARGET_DIR}/.kiro/steering/obsidian-wiki.md"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
