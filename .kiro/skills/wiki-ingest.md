# Wiki Ingest — Source Ingestion

## Description
Reads a source document, extracts entities and concepts, creates or updates wiki pages, cross-references everything, and logs the operation. Supports files, URLs, images, and batch mode.

## Triggers
- "ingest [file]"
- "process this source"
- "add this to the wiki"
- "read and file this"
- "batch ingest"
- "ingest all of these"
- "ingest this url"

## Instructions

Read the source. Write the wiki. Cross-reference everything. A single source typically touches 8-15 wiki pages.

### Transport

Before mutating any vault file, check `.vault-meta/transport.json`:
- **cli** — `obsidian-cli write "$VAULT" "$NOTE" < content.md`
- **mcp** — MCP tools if configured
- **filesystem** — direct file writes (always works)

### Mode Awareness

Before creating any new page, consult the methodology mode:
```bash
python3 scripts/wiki-mode.py route <type> "<name>"
```
This returns the correct vault-relative path for the page based on the active mode.

### Concurrency

Every wiki page write MUST be preceded by lock acquisition:
```bash
bash scripts/wiki-lock.sh acquire <path>
# ... write ...
bash scripts/wiki-lock.sh release <path>
```

### Delta Tracking

Before ingesting, check `.raw/.manifest.json` to avoid re-processing unchanged sources:
1. Compute hash: `md5sum [file] | cut -d' ' -f1`
2. If hash matches manifest entry, skip (report "Already ingested")
3. After ingesting, record hash + pages created/updated in manifest

### URL Ingestion

When user passes a URL:
1. Fetch the page content
2. Clean with defuddle if available
3. Save to `.raw/articles/[slug]-[YYYY-MM-DD].md`
4. Proceed with single source ingest

### Single Source Ingest Workflow

1. **Read** the source completely — no skimming
2. **Discuss** key takeaways (skip if user says "just ingest it")
3. **Create** source summary page in the appropriate wiki folder
4. **Create or update** entity pages for every person, org, product mentioned
5. **Create or update** concept pages for significant ideas and frameworks
6. **Update** relevant domain pages and sub-indexes
7. **Update** `wiki/overview.md` if the big picture changed
8. **Update** `wiki/index.md` — add entries for all new pages
9. **Update** `wiki/hot.md` with this ingest's context
10. **Append** to `wiki/log.md` (new entries at TOP):
    ```
    ## [YYYY-MM-DD] ingest | Source Title
    - Source: `.raw/articles/filename.md`
    - Pages created: [[Page 1]], [[Page 2]]
    - Key insight: One sentence on what is new.
    ```
11. **Check for contradictions** — add `> [!contradiction]` callouts if conflicts found

### Batch Ingest

1. List all files to process, confirm with user
2. Process each source following single ingest flow
3. After all sources: cross-reference pass
4. Update index, hot cache, and log once at the end
5. Report summary

### Frontmatter Schema (Sources)

```yaml
---
type: source
title: "Source Title"
source_type: article | paper | book | video | podcast | website
author: "Author Name"
date_published: YYYY-MM-DD
url: "https://..."
confidence: high | medium | low
key_claims:
  - "Claim 1"
  - "Claim 2"
created: YYYY-MM-DD
updated: YYYY-MM-DD
tags: [source, domain-tag]
status: developing
related:
  - "[[Related Page]]"
---
```

### Contradictions

When new info contradicts existing pages, add callouts on BOTH pages:
```markdown
> [!contradiction] Conflict with [[New Source]]
> [[Existing Page]] claims X. [[New Source]] says Y.
> Needs resolution.
```

Do NOT silently overwrite old claims. Flag and let the user decide.

### Rules
- Source files under `.raw/` are **immutable** — never modify them
- Always check the index before creating pages (avoid duplicates)
- Every ingest must be recorded in the log
- Always update the hot cache
- Keep wiki pages under 300 lines; split if longer
