# Wiki Lint — Vault Health Check

## Description
Health-checks the Obsidian wiki vault. Finds orphan pages, dead wikilinks, stale claims, missing cross-references, frontmatter gaps, and empty sections. Generates reports and dashboards.

## Triggers
- "lint"
- "health check"
- "clean up wiki"
- "check the wiki"
- "wiki maintenance"
- "find orphans"
- "wiki audit"

## Instructions

Run lint after every 10-15 ingests, or weekly. Ask before auto-fixing anything. Output a lint report to `wiki/meta/lint-report-YYYY-MM-DD.md`.

### Lint Checks (in order)

1. **Orphan pages** — wiki pages with no inbound wikilinks
2. **Dead links** — wikilinks referencing pages that don't exist
3. **Stale claims** — assertions contradicted by newer sources
4. **Missing pages** — concepts/entities mentioned multiple times but lacking their own page
5. **Missing cross-references** — entities mentioned but not linked
6. **Frontmatter gaps** — pages missing required fields (type, status, created, updated, tags)
7. **Empty sections** — headings with no content underneath
8. **Stale index entries** — items in `wiki/index.md` pointing to renamed/deleted pages

### Optional Checks (if provisioned)

9. **Address validation** (DragonScale) — if `scripts/allocate-address.sh` exists
10. **Semantic tiling** — if `scripts/tiling-check.py` exists, flag candidate duplicates via cosine similarity

### Lint Report Format

Create at `wiki/meta/lint-report-YYYY-MM-DD.md`:

```markdown
---
type: meta
title: "Lint Report YYYY-MM-DD"
created: YYYY-MM-DD
tags: [meta, lint]
---

# Lint Report: YYYY-MM-DD

## Summary
- Pages scanned: N
- Issues found: N
- Auto-fixed: N
- Needs review: N

## Orphan Pages
- [[Page Name]]: no inbound links. Suggest: link from [[Related Page]] or delete.

## Dead Links
- [[Missing Page]]: referenced in [[Source Page]]. Suggest: create stub or remove link.

## Missing Pages
- "concept name": mentioned in [[Page A]], [[Page B]]. Suggest: create a concept page.

## Frontmatter Gaps
- [[Page Name]]: missing fields: status, tags

## Stale Claims
- [[Page Name]]: claim "X" may conflict with [[Newer Source]].

## Cross-Reference Gaps
- [[Entity Name]] mentioned in [[Page A]] without a wikilink.
```

### Naming Conventions to Enforce

| Element | Convention | Example |
|---------|-----------|---------|
| Filenames | Title Case with spaces | `Machine Learning.md` |
| Folders | lowercase with dashes | `wiki/data-models/` |
| Tags | lowercase, hierarchical | `#domain/architecture` |
| Wikilinks | match filename exactly | `[[Machine Learning]]` |

### Auto-Fix Rules

**Safe to auto-fix** (after confirmation):
- Adding missing frontmatter fields with placeholders
- Creating stub pages for missing entities
- Adding wikilinks for unlinked mentions

**Needs review before fixing**:
- Deleting orphan pages (might be intentionally isolated)
- Resolving contradictions (requires human judgment)
- Merging duplicate pages

Always show the lint report first and ask: "Should I fix these automatically, or do you want to review each one?"

### Dataview Dashboard

Create or update `wiki/meta/dashboard.md` with Dataview queries for:
- Recent activity (last 15 modified pages)
- Seed pages needing development
- Entities missing sources
- Open questions
