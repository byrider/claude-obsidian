#!/usr/bin/env bash
# install-kiro.sh — Install claude-obsidian Kiro skills into any project or vault
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/byrider/claude-obsidian/kiro-port/bin/install-kiro.sh | bash
#
# Or locally:
#   bash bin/install-kiro.sh [target-directory]
#
# What it does:
#   1. Downloads the .kiro/ directory (skills, hooks, steering)
#   2. Downloads supporting scripts (wiki-lock, wiki-mode, detect-transport, etc.)
#   3. Downloads templates and bin/setup-kiro-vault.sh
#   4. Runs setup-kiro-vault.sh to configure Obsidian and wiki structure
#   5. Reports what was installed

set -euo pipefail

# --- Configuration ---
REPO_OWNER="byrider"
REPO_NAME="claude-obsidian"
BRANCH="kiro-port"
RAW_BASE="https://raw.githubusercontent.com/${REPO_OWNER}/${REPO_NAME}/${BRANCH}"

# --- Target directory ---
TARGET_DIR="${1:-$(pwd)}"
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

# Helper: download a file
download() {
  local url="$1"
  local dest="$2"
  mkdir -p "$(dirname "$dest")"
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$url" -o "$dest" 2>/dev/null
  else
    wget -q "$url" -O "$dest" 2>/dev/null
  fi
}

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
  download "${RAW_BASE}/.kiro/skills/${skill}/SKILL.md" \
           "${TARGET_DIR}/.kiro/skills/${skill}/SKILL.md"
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
  download "${RAW_BASE}/.kiro/hooks/${hook}.kiro.hook" \
           "${TARGET_DIR}/.kiro/hooks/${hook}.kiro.hook"
done
echo "  ✓ ${#HOOKS[@]} hooks installed"

# --- Step 3: Install steering ---
echo ""
echo "[3/5] Installing steering file..."
download "${RAW_BASE}/.kiro/steering/obsidian-wiki.md" \
         "${TARGET_DIR}/.kiro/steering/obsidian-wiki.md"
download "${RAW_BASE}/.kiro/README.md" \
         "${TARGET_DIR}/.kiro/README.md"
echo "  ✓ Steering + README installed"

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
  if download "${RAW_BASE}/${script}" "${TARGET_DIR}/${script}" 2>/dev/null; then
    chmod +x "${TARGET_DIR}/${script}" 2>/dev/null || true
    SCRIPT_OK=$((SCRIPT_OK + 1))
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
  if download "${RAW_BASE}/${tpl}" "${TARGET_DIR}/${tpl}" 2>/dev/null; then
    TPL_OK=$((TPL_OK + 1))
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
