#!/usr/bin/env bash
# setup-kiro-vault.sh — One-shot setup for claude-obsidian as a Kiro-powered vault
# Run once after cloning. Sets up Obsidian config, CSS snippets, and verifies .kiro structure.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VAULT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  claude-obsidian: Kiro Vault Setup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# --- 1. Verify .kiro structure exists ---
echo "[1/7] Verifying .kiro structure..."
if [ -d "$VAULT_ROOT/.kiro/skills" ] && [ -d "$VAULT_ROOT/.kiro/hooks" ] && [ -d "$VAULT_ROOT/.kiro/steering" ]; then
  SKILL_COUNT=$(find "$VAULT_ROOT/.kiro/skills" -name "*.md" | wc -l)
  HOOK_COUNT=$(find "$VAULT_ROOT/.kiro/hooks" -name "*.kiro.hook" | wc -l)
  echo "  ✓ .kiro/skills/: $SKILL_COUNT skills"
  echo "  ✓ .kiro/hooks/:  $HOOK_COUNT hooks"
  echo "  ✓ .kiro/steering/: present"
else
  echo "  ✗ .kiro/ structure incomplete. Ensure the repo was cloned fully."
  exit 1
fi

# --- 2. Ensure .obsidian directory exists ---
echo ""
echo "[2/7] Setting up .obsidian configuration..."
mkdir -p "$VAULT_ROOT/.obsidian/snippets"
mkdir -p "$VAULT_ROOT/.obsidian/plugins"

# --- 3. Configure graph.json for color-coded graph view ---
if [ ! -f "$VAULT_ROOT/.obsidian/graph.json" ]; then
  cat > "$VAULT_ROOT/.obsidian/graph.json" << 'EOF'
{
  "collapse-filter": false,
  "search": "",
  "showTags": false,
  "showAttachments": false,
  "hideUnresolved": false,
  "showOrphans": true,
  "collapse-color-groups": false,
  "colorGroups": [
    {"query": "path:wiki/concepts", "color": {"a": 1, "rgb": 4488191}},
    {"query": "path:wiki/entities", "color": {"a": 1, "rgb": 11141290}},
    {"query": "path:wiki/sources", "color": {"a": 1, "rgb": 5025616}},
    {"query": "path:wiki/questions", "color": {"a": 1, "rgb": 16750848}},
    {"query": "path:wiki/sessions", "color": {"a": 1, "rgb": 8388736}}
  ],
  "collapse-display": false,
  "lineSizeMultiplier": 1,
  "nodeSizeMultiplier": 1,
  "collapse-forces": false,
  "centerStrength": 0.518713248970312,
  "repelStrength": 10,
  "linkStrength": 1,
  "linkDistance": 250,
  "scale": 1
}
EOF
  echo "  ✓ graph.json created (color-coded groups)"
else
  echo "  ○ graph.json already exists (skipped)"
fi

# --- 4. Configure app.json to exclude plugin/build dirs ---
if [ ! -f "$VAULT_ROOT/.obsidian/app.json" ]; then
  cat > "$VAULT_ROOT/.obsidian/app.json" << 'EOF'
{
  "userIgnoreFilters": [
    "node_modules/",
    ".git/",
    "bin/",
    "scripts/",
    "tests/",
    ".kiro/",
    ".claude-plugin/",
    ".cursor/",
    ".windsurf/"
  ],
  "showUnsupportedFiles": false,
  "strictLineBreaks": false,
  "showFrontmatter": true
}
EOF
  echo "  ✓ app.json created (excluded dirs configured)"
else
  echo "  ○ app.json already exists (skipped)"
fi

# --- 5. Enable CSS snippets ---
echo ""
echo "[3/7] Enabling CSS snippets..."
if [ -f "$VAULT_ROOT/.obsidian/snippets/vault-colors.css" ]; then
  echo "  ✓ vault-colors.css present"
else
  cat > "$VAULT_ROOT/.obsidian/snippets/vault-colors.css" << 'EOF'
/* claude-obsidian vault colors — color-coded file explorer */
.nav-file-title[data-path^="wiki/concepts"] { color: var(--text-accent) !important; }
.nav-file-title[data-path^="wiki/entities"] { color: #a855f7 !important; }
.nav-file-title[data-path^="wiki/sources"] { color: #22c55e !important; }
.nav-file-title[data-path^="wiki/questions"] { color: #f97316 !important; }
.nav-file-title[data-path^="wiki/sessions"] { color: #8b5cf6 !important; }

/* Custom callout types */
.callout[data-callout="contradiction"] { --callout-color: 180, 65, 40; --callout-icon: alert-triangle; }
.callout[data-callout="gap"] { --callout-color: 200, 150, 50; --callout-icon: help-circle; }
.callout[data-callout="key-insight"] { --callout-color: 50, 160, 80; --callout-icon: lightbulb; }
.callout[data-callout="stale"] { --callout-color: 130, 130, 130; --callout-icon: clock; }
EOF
  echo "  ✓ vault-colors.css created"
fi

# Configure appearance to enable the snippet
if [ ! -f "$VAULT_ROOT/.obsidian/appearance.json" ]; then
  cat > "$VAULT_ROOT/.obsidian/appearance.json" << 'EOF'
{
  "enabledCssSnippets": ["vault-colors", "ITS-Dataview-Cards", "ITS-Image-Adjustments"]
}
EOF
  echo "  ✓ appearance.json created (snippets enabled)"
else
  echo "  ○ appearance.json already exists (skipped)"
fi

# --- 6. Set up vault-meta ---
echo ""
echo "[4/7] Setting up .vault-meta..."
mkdir -p "$VAULT_ROOT/.vault-meta/locks"

if [ ! -f "$VAULT_ROOT/.vault-meta/transport.json" ]; then
  # Auto-detect transport
  if [ -x "$VAULT_ROOT/scripts/detect-transport.sh" ]; then
    bash "$VAULT_ROOT/scripts/detect-transport.sh" 2>/dev/null || true
    echo "  ✓ Transport auto-detected"
  else
    cat > "$VAULT_ROOT/.vault-meta/transport.json" << 'EOF'
{
  "preferred": "filesystem",
  "detected_at": "auto",
  "manual_override": false
}
EOF
    echo "  ✓ transport.json created (filesystem default)"
  fi
else
  echo "  ○ transport.json already exists"
fi

# --- 7. Ensure wiki structure exists ---
echo ""
echo "[5/7] Verifying wiki structure..."
DIRS=("wiki/sources" "wiki/entities" "wiki/concepts" "wiki/questions" "wiki/sessions" "wiki/meta" "wiki/folds")
for dir in "${DIRS[@]}"; do
  mkdir -p "$VAULT_ROOT/$dir"
done
echo "  ✓ Wiki directories present"

# Create hot.md if missing
if [ ! -f "$VAULT_ROOT/wiki/hot.md" ]; then
  cat > "$VAULT_ROOT/wiki/hot.md" << EOF
---
type: meta
title: "Hot Cache"
updated: $(date '+%Y-%m-%dT%H:%M:%S')
---

# Recent Context

## Last Updated
Vault freshly initialized. No ingests yet.

## Key Recent Facts
- Vault set up with Kiro skills and hooks
- Ready for first source ingest

## Recent Changes
- Initial scaffold

## Active Threads
- Awaiting first source ingest
EOF
  echo "  ✓ wiki/hot.md created"
fi

# Create index.md if missing
if [ ! -f "$VAULT_ROOT/wiki/index.md" ]; then
  cat > "$VAULT_ROOT/wiki/index.md" << EOF
---
type: meta
title: "Master Index"
updated: $(date '+%Y-%m-%d')
---

# Wiki Index

## Domains

## Entities

## Concepts

## Sources

## Questions

## Sessions
EOF
  echo "  ✓ wiki/index.md created"
fi

# Create log.md if missing
if [ ! -f "$VAULT_ROOT/wiki/log.md" ]; then
  cat > "$VAULT_ROOT/wiki/log.md" << 'EOF'
---
type: meta
title: "Operation Log"
---

# Operation Log

<!-- New entries go at the TOP. This is append-only (never edit past entries). -->
EOF
  echo "  ✓ wiki/log.md created"
fi

# --- 8. Ensure .raw directory ---
echo ""
echo "[6/7] Verifying .raw directory..."
mkdir -p "$VAULT_ROOT/.raw"
if [ ! -f "$VAULT_ROOT/.raw/.manifest.json" ]; then
  echo '{"sources": {}, "address_map": {}}' > "$VAULT_ROOT/.raw/.manifest.json"
  echo "  ✓ .raw/.manifest.json created"
else
  echo "  ○ .raw/.manifest.json already exists"
fi

# --- 9. Final summary ---
echo ""
echo "[7/7] Setup complete!"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Kiro Vault Ready"
echo ""
echo "  Next steps:"
echo "    1. Open this folder in Obsidian (Manage Vaults → Open folder as vault)"
echo "    2. Open Kiro in this workspace"
echo "    3. Say '/wiki' to check status or start ingesting"
echo ""
echo "  Skills installed:  $SKILL_COUNT"
echo "  Hooks installed:   $HOOK_COUNT"
echo "  Steering files:    1"
echo ""
echo "  Skills available:"
echo "    /wiki           - Setup, scaffold, status check"
echo "    ingest [file]   - Ingest a source document"
echo "    query: [Q]      - Ask the wiki a question"
echo "    lint            - Health check the vault"
echo "    /save           - File conversation as wiki page"
echo "    /autoresearch   - Autonomous research loop"
echo "    /think          - 10-principle structured reasoning"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
