# claude-obsidian — Kiro Port

Kiro-native skills, hooks, and steering for the [claude-obsidian](https://github.com/AgriciDaniel/claude-obsidian) self-organizing AI second brain.

## Quick Start

```bash
git clone https://github.com/byrider/claude-obsidian
cd claude-obsidian
bash bin/setup-kiro-vault.sh
```

Open the folder in Obsidian, open Kiro in the same workspace, and say `/wiki`.

## What's Included

### Skills (9)

| Skill | Trigger | What it does |
|-------|---------|--------------|
| `wiki-setup` | `/wiki`, "scaffold vault" | First-run vault setup, scaffolding, status checks |
| `wiki-ingest` | "ingest [file]", "add this to wiki" | Reads sources, extracts entities/concepts, files wiki pages |
| `wiki-code-ingest` | "ingest codebase", "ingest this code summary" | Handles volatile source code, Kiro `/code summary` outputs, API specs, schemas. Updates existing pages instead of creating duplicates |
| `wiki-query` | "what do you know about X", "query:" | Answers questions from the vault with citations |
| `wiki-lint` | "lint", "health check" | Finds orphans, dead links, stale claims, frontmatter gaps |
| `wiki-save` | `/save`, "file this" | Files conversations/insights as structured wiki pages |
| `wiki-autoresearch` | `/autoresearch [topic]` | Autonomous web research loop: search, fetch, synthesize, file |
| `wiki-session-harvest` | "harvest sessions", "import my sessions" | Discovers and ingests past Kiro IDE/CLI and Claude Code sessions |
| `wiki-think` | `/think [problem]` | 10-principle structured reasoning framework |

### Hooks (5)

| Hook | Event | Action |
|------|-------|--------|
| `hot-cache-on-save` | `fileEdited` on `wiki/**/*.md` | Updates `wiki/hot.md` with change summary (askAgent) |
| `auto-commit-wiki` | `fileEdited` on `wiki/**/*` | Auto-stages and commits wiki changes if no locks held (runCommand) |
| `session-context` | `promptSubmit` | Loads `wiki/hot.md` into context for session continuity (runCommand) |
| `session-end-summary` | `agentStop` | Summarizes wiki changes made during the session (askAgent) |
| `clear-stale-locks` | `promptSubmit` | Cleans advisory locks older than 1 hour (runCommand) |

### Steering (1)

| File | Purpose |
|------|---------|
| `obsidian-wiki.md` | Project conventions, vault structure, transport, methodology modes, concurrency rules |

## Directory Structure

```
.kiro/
├── README.md                              # This file
├── steering/
│   └── obsidian-wiki.md                   # Project conventions
├── skills/
│   ├── wiki-setup/SKILL.md                # Vault scaffold
│   ├── wiki-ingest/SKILL.md               # Source ingestion
│   ├── wiki-code-ingest/SKILL.md          # Codebase context (volatile)
│   ├── wiki-query/SKILL.md                # Query with citations
│   ├── wiki-lint/SKILL.md                 # Health check
│   ├── wiki-save/SKILL.md                 # File conversations
│   ├── wiki-autoresearch/SKILL.md         # Autonomous research
│   ├── wiki-session-harvest/SKILL.md      # Import CLI/IDE sessions
│   └── wiki-think/SKILL.md                # Structured reasoning
└── hooks/
    ├── hot-cache-on-save.kiro.hook         # Update hot cache on wiki edits
    ├── auto-commit-wiki.kiro.hook          # Git auto-commit wiki changes
    ├── session-context.kiro.hook           # Load hot cache on prompt
    ├── session-end-summary.kiro.hook       # Summarize changes on stop
    └── clear-stale-locks.kiro.hook         # Clean stale advisory locks
```

## Skill Format

Skills follow the [Agent Skills standard](https://agentskills.io):
- Each skill is a directory containing a `SKILL.md` file
- `SKILL.md` has YAML frontmatter (`name`, `description`, `allowed-tools`) followed by Markdown instructions
- Names are lowercase-hyphenated, max 64 characters
- Kiro activates skills automatically when your prompt matches the description, or you can invoke them directly

## Hook Format

Hooks follow Kiro's `.kiro.hook` JSON format:
- `enabled`: boolean
- `name` / `description`: human-readable metadata
- `version`: "1"
- `when.type`: `fileEdited` | `fileCreated` | `fileDeleted` | `agentStop` | `promptSubmit` | `manual`
- `when.patterns`: glob patterns for file-scoped triggers
- `then.type`: `askAgent` (sends prompt to Kiro) or `runCommand` (executes shell command)

## Methodology Modes

The vault supports four organizational philosophies (set via `bin/setup-mode.sh`):

| Mode | Description |
|------|-------------|
| **Generic** (default) | `wiki/sources/`, `wiki/entities/`, `wiki/concepts/` |
| **LYT** | MOCs + atomic notes |
| **PARA** | Projects / Areas / Resources / Archives |
| **Zettelkasten** | Flat, timestamped IDs, dense linking |

## Relationship to Original

This is a Kiro-native port of [AgriciDaniel/claude-obsidian](https://github.com/AgriciDaniel/claude-obsidian). The original is a Claude Code plugin with 15 skills. This port:

- Converts the core skills to Kiro's `SKILL.md` format (directory-based, YAML frontmatter)
- Converts hooks from Claude Code's `hooks.json` to Kiro's `.kiro.hook` format
- Converts `CLAUDE.md` project instructions to Kiro steering files
- Adds new Kiro-specific skills: `wiki-code-ingest` (for `/code summary` integration) and `wiki-session-harvest` (for importing Kiro/Claude sessions)
- Reuses the existing `scripts/`, `bin/`, `_templates/`, and wiki structure unchanged

## Requirements

- [Obsidian](https://obsidian.md) v1.9.10+
- [Kiro](https://kiro.dev) (IDE or CLI)
- Git (for auto-commit hooks and version tracking)
- Python 3 (for `scripts/wiki-mode.py` mode routing)

## License

MIT — same as the original claude-obsidian project.
