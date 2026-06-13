---
name: wiki-code-ingest
description: >
  Ingests codebase context into the wiki vault. Handles source code that changes
  frequently by tracking snapshots, architecture summaries, and code intelligence
  outputs. Supports Kiro /code summary outputs, git diffs, API specs, and schema
  files. Updates existing wiki pages rather than creating duplicates.
  Triggers on: "ingest codebase", "ingest this code summary", "update code wiki",
  "map this codebase", "ingest architecture", "code context update",
  "sync code to wiki", "refresh code pages".
allowed-tools: Read Write Edit Glob Grep Bash
---

# Wiki Code Ingest — Codebase Context for the Wiki

Source code is volatile. This skill handles that by treating code context as **living pages** that get updated, not appended. Architecture stays current. Implementation details track major versions.

## Key Difference from wiki-ingest

| | wiki-ingest | wiki-code-ingest |
|---|---|---|
| Source type | Static (articles, papers, sessions) | Volatile (code, APIs, schemas) |
| Behavior on re-ingest | Creates new source page | **Updates existing** code pages |
| Tracking | `.raw/.manifest.json` hash | Git commit SHA + timestamp |
| Freshness | Ingest once, done | Re-ingest on change |

## Input Sources

### A. Kiro `/code summary` Output

When the user says "ingest this code summary" after running `/code summary`:
1. Capture the summary output (from chat context or clipboard)
2. Parse into: architecture overview, module list, patterns, dependencies
3. Create or **update** `wiki/codebases/<project-name>.md`
4. Extract entities (services, modules, key classes)
5. Extract concepts (patterns, architecture decisions)

### B. Direct Codebase Scan

When the user says "map this codebase" or "ingest codebase [path]":
1. Read the project structure: `find . -type f | head -200` or `tree -L 3`
2. Identify key files: README, package.json/Cargo.toml/go.mod, API specs, schemas
3. Read and summarize architecture-level files only (not every source file)
4. Create the codebase map page

### C. API Specs / Schemas

When the user points at specific contract files:
- OpenAPI/Swagger YAML/JSON → extract endpoints, models, auth
- GraphQL schemas → extract types, queries, mutations
- Database schemas (SQL/Prisma/etc.) → extract tables, relationships
- Proto files → extract services, messages

### D. Git Diff / Release Notes

When the user says "update code wiki" or on a hook trigger:
1. Run `git log --oneline -20` to see recent changes
2. Run `git diff <last-ingested-sha>..HEAD --stat` to see what moved
3. Update existing wiki pages for changed modules
4. Add new pages for new modules/services
5. Mark removed modules as archived

## Codebase Map Page

The central page for each codebase:

```yaml
---
type: codebase
title: "[Project Name] — Codebase Map"
project_path: "/path/to/project"
last_ingested_sha: "abc123f"
last_ingested_date: YYYY-MM-DD
language: typescript | python | rust | go | mixed
status: developing
tags: [codebase, project-name]
related:
  - "[[Module pages]]"
---
```

```markdown
# [Project Name] — Codebase Map

## Overview
[2-3 sentence architecture summary]

## Tech Stack
- Language: [X]
- Framework: [X]
- Database: [X]
- Deployment: [X]

## Module Map
| Module | Path | Purpose | Key Patterns |
|--------|------|---------|--------------|
| [[Auth Module]] | src/auth/ | Authentication + authorization | JWT, RBAC |
| [[API Layer]] | src/api/ | REST endpoints | Express, middleware chain |

## Architecture Decisions
- [[ADR: Why We Chose X]]: rationale
- [[ADR: Database Strategy]]: rationale

## Dependencies (notable)
- [dep]: what it does, why it's here
- [dep]: what it does, why it's here

## API Surface
- [See [[API Spec Page]] for full endpoints]

## Data Model
- [See [[Schema Page]] for tables/relationships]

## Recent Changes
- [YYYY-MM-DD]: [what changed]
- [YYYY-MM-DD]: [what changed]
```

## Update vs. Create Logic

Before writing any code page, check if it already exists:

```bash
# Check for existing codebase map
EXISTING=$(find wiki/codebases -name "*project-name*" 2>/dev/null | head -1)
if [ -n "$EXISTING" ]; then
  # UPDATE mode: read existing, merge new info, preserve manual edits
else
  # CREATE mode: new codebase map from scratch
fi
```

**Update rules:**
- Preserve any section the user manually edited (check git blame or `[manual]` markers)
- Update the `last_ingested_sha` and `last_ingested_date` frontmatter
- Add new modules, mark removed ones as `[archived]`
- Update the "Recent Changes" section
- Do NOT regenerate sections that haven't changed

## Freshness Tracking

Store ingest state in `.vault-meta/code-ingests.json`:

```json
{
  "codebases": {
    "/path/to/project": {
      "wiki_page": "wiki/codebases/Project Name.md",
      "last_sha": "abc123f",
      "last_date": "2026-06-13",
      "modules_tracked": ["src/auth/", "src/api/", "src/db/"],
      "auto_refresh": false
    }
  }
}
```

## Auto-Refresh Hook (optional)

If the user wants code pages to stay current automatically, suggest adding a hook:

```json
{
  "enabled": true,
  "name": "Refresh Code Wiki on Push",
  "version": "1",
  "when": { "type": "manual" },
  "then": {
    "type": "askAgent",
    "prompt": "Run wiki-code-ingest in update mode for all tracked codebases. Check git log since last ingested SHA, update wiki pages for any modules that changed."
  }
}
```

This is intentionally a **manual** trigger, not automatic — code changes too often for automatic ingestion to be practical. The user runs it when they want a refresh.

## /code summary Integration

When Kiro's `/code summary` output is available:
1. It's already a synthesized overview — don't re-analyze the code
2. Parse the summary sections directly into wiki page format
3. Save the raw summary to `.raw/code-summaries/<project>-<date>.md`
4. Create/update the codebase map page from the summary content
5. The raw summary serves as the "source of record" for that snapshot

## Mode Awareness

Route codebase pages through the mode router:
```bash
python3 scripts/wiki-mode.py route source "<project-name> codebase"
```

For sub-pages (modules, APIs):
```bash
python3 scripts/wiki-mode.py route entity "<module-name>"
python3 scripts/wiki-mode.py route concept "<pattern-name>"
```

## Filing Location

Default (generic mode):
```
wiki/
├── codebases/
│   └── Project Name.md          # codebase map (central page)
├── entities/
│   ├── Auth Module.md           # module pages
│   └── API Layer.md
├── concepts/
│   ├── JWT Authentication.md    # patterns found in code
│   └── Event Sourcing.md
└── sources/
    └── Project Name API Spec.md # API/schema docs
```

## Concurrency

Lock before writing:
```bash
bash scripts/wiki-lock.sh acquire "$NOTE_PATH"
# ... write ...
bash scripts/wiki-lock.sh release "$NOTE_PATH"
```
