# claude-obsidian — Obsidian Wiki Vault for Kiro

This workspace is both a Kiro-enhanced project and an Obsidian vault.

## Overview

A persistent, compounding wiki vault powered by Kiro. Sources get ingested, entities and concepts get extracted, cross-references build automatically, and knowledge compounds with every session. Based on Andrej Karpathy's LLM Wiki pattern.

## Vault Structure

```
.raw/           Source documents — immutable, Kiro reads but never modifies
wiki/           Kiro-generated knowledge base
_templates/     Obsidian Templater templates
_attachments/   Images and PDFs referenced by wiki pages
.vault-meta/    Internal metadata (locks, transport, mode, counters)
```

## How to Use

- Drop a source file into `.raw/`, then tell Kiro: "ingest [filename]"
- Ask any question — Kiro reads the index first, then drills into relevant pages
- Say "lint the wiki" every 10-15 ingests to catch orphans and gaps
- Say "/save" to file conversation insights as wiki pages
- Say "/autoresearch [topic]" for autonomous web research loops
- Say "/think [problem]" for structured 10-principle reasoning

## Core Conventions

### Frontmatter (required on all wiki pages)
- `type`: source | entity | concept | question | session | meta | decision
- `status`: seed | developing | solid | authoritative
- `created`: YYYY-MM-DD
- `updated`: YYYY-MM-DD
- `tags`: array of relevant tags

### Wikilinks
- Use `[[Note Name]]` format — filenames are unique, no paths needed
- `.raw/` contains source documents — never modify them
- `wiki/index.md` is the master catalog — update on every ingest
- `wiki/log.md` is append-only — new entries go at the TOP

### Hot Cache
- `wiki/hot.md` is a ~500-word summary of recent context
- Update after every ingest, significant query, or session end
- Any session starts by reading hot.md to restore context

## Transport

The vault supports multiple write transports (detected via `scripts/detect-transport.sh`):
1. **Obsidian CLI** — `obsidian-cli write "$VAULT" "$NOTE" < content.md`
2. **MCP (mcp-obsidian/mcpvault)** — via MCP tools
3. **Filesystem** — direct file writes (always-available fallback)

Check `.vault-meta/transport.json` before mutating vault files.

## Methodology Modes

The vault supports four organizational philosophies (set via `bin/setup-mode.sh`):

| Mode | Filing Convention |
|------|-------------------|
| **Generic** (default) | `wiki/sources/`, `wiki/entities/`, `wiki/concepts/`, `wiki/sessions/` |
| **LYT** | `wiki/mocs/` + `wiki/notes/` (MOCs as navigation) |
| **PARA** | `wiki/projects/`, `wiki/areas/`, `wiki/resources/`, `wiki/archives/` |
| **Zettelkasten** | `wiki/<timestamp-id>-<slug>.md` (flat, dense linking) |

Before creating pages, consult: `python3 scripts/wiki-mode.py route <type> "<name>"`

## Concurrency

Per-file advisory locks via `scripts/wiki-lock.sh`:
```bash
bash scripts/wiki-lock.sh acquire <path>
# ... write ...
bash scripts/wiki-lock.sh release <path>
```

## Cross-Project Knowledge Base

To reference this vault from another project, add to that project's steering:
```
When you need context not in this project:
1. Read wiki/hot.md first (~500 words of recent context)
2. If not enough, read wiki/index.md
3. Then drill into specific wiki pages
```

## Skills Available

| Skill | Trigger |
|-------|---------|
| wiki-setup | "set up wiki", "scaffold vault", "/wiki" |
| wiki-ingest | "ingest [source]", "process this", "add this to the wiki" |
| wiki-query | "what do you know about X", "query:", questions about wiki content |
| wiki-lint | "lint", "health check", "clean up wiki" |
| wiki-save | "/save", "save this", "file this conversation" |
| wiki-autoresearch | "/autoresearch [topic]", "research [topic]" |
| wiki-think | "/think [problem]", "think this through" |
