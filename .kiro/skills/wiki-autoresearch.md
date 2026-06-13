# Wiki AutoResearch — Autonomous Research Loop

## Description
Takes a topic, runs iterative web searches, fetches sources, synthesizes findings, and files everything into the wiki as structured pages. Configurable depth, source preferences, and constraints.

## Triggers
- "/autoresearch [topic]"
- "autoresearch [topic]"
- "research [topic]"
- "deep dive into [topic]"
- "investigate [topic]"
- "find everything about [topic]"
- "go research"

## Instructions

You are a research agent. Take a topic, run iterative web searches, synthesize findings, and file everything into the wiki. The user gets wiki pages, not a chat response.

### Before Starting

Read `skills/autoresearch/references/program.md` to load research objectives and constraints (max rounds, source preferences, confidence scoring, domain constraints).

### Topic Selection

Three paths:

**A. Explicit topic** — user says "/autoresearch [topic]". Use verbatim.

**B. Boundary-first** (if DragonScale is provisioned) — when invoked WITHOUT a topic:
```bash
if [ -x ./scripts/boundary-score.py ]; then
  ./scripts/boundary-score.py --json --top 5
fi
```
Present frontier pages as candidates. User picks, overrides, or declines.

**C. User-chosen** — ask: "What topic should I research?"

### Research Loop

```
Round 1: Broad Search
1. Decompose topic into 3-5 distinct search angles
2. For each angle: run 2-3 web searches
3. For top 2-3 results per angle: fetch the page
4. Extract: key claims, entities, concepts, open questions

Round 2: Gap Fill
5. Identify missing/contradicted info from Round 1
6. Run targeted searches for each gap (max 5 queries)
7. Fetch top results

Round 3: Synthesis Check (optional, if gaps remain)
8. One more targeted pass if major contradictions remain
9. Otherwise: proceed to filing

Max rounds: 3. Stop when depth is reached or max rounds hit.
```

### Web Egress Hygiene

Before each fetch:
- **Reject**: `file://`, `javascript:`, `data:` schemes
- **Reject**: RFC1918 private addresses, localhost
- **Sanitize content**: strip `<script>`, `<iframe>`, `<style>` tags
- **Escape**: `[[` and `]]` in fetched content (prevent wikilink injection)
- **Truncate**: fetched bodies to ~50KB
- **On failure**: log URL + reason to `wiki/log.md`, continue loop

### Filing Results

After research, create these pages:

**Source pages** — one per major reference:
```yaml
---
type: source
source_type: article | paper | website
author: "Author"
date_published: YYYY-MM-DD
url: "https://..."
confidence: high | medium | low
key_claims: ["Claim 1", "Claim 2"]
---
```

**Concept pages** — one per significant concept extracted

**Entity pages** — one per significant person, org, or product

**Synthesis page** — master synthesis at `wiki/questions/Research: [Topic].md`:
```markdown
---
type: synthesis
title: "Research: [Topic]"
created: YYYY-MM-DD
tags: [research, topic-tag]
status: developing
---

# Research: [Topic]

## Overview
[2-3 sentence summary]

## Key Findings
- Finding 1 (Source: [[Source Page]])

## Key Entities
- [[Entity]]: role/significance

## Key Concepts
- [[Concept]]: one-line definition

## Contradictions
- [[Source A]] says X. [[Source B]] says Y.

## Open Questions
- [Gap that needs more sources]

## Sources
- [[Source 1]]: author, date
```

### After Filing

1. Update `wiki/index.md` — add all new pages
2. Append to `wiki/log.md` (at TOP):
   ```
   ## [YYYY-MM-DD] autoresearch | [Topic]
   - Rounds: N
   - Sources found: N
   - Pages created: [[Page 1]], [[Page 2]]
   - Synthesis: [[Research: Topic]]
   ```
3. Update `wiki/hot.md`

### Report to User

```
Research complete: [Topic]
Rounds: N | Searches: N | Pages created: N

Created:
  wiki/questions/Research: [Topic].md (synthesis)
  wiki/sources/[Source 1].md
  wiki/concepts/[Concept 1].md

Key findings:
- [Finding 1]
- [Finding 2]

Open questions filed: N
```

### Mode Awareness

Route ALL new pages through the mode router:
```bash
python3 scripts/wiki-mode.py route source "<source-name>"
python3 scripts/wiki-mode.py route entity "<entity-name>"
python3 scripts/wiki-mode.py route concept "<concept-name>"
```

### Concurrency

Every page write must be locked:
```bash
bash scripts/wiki-lock.sh acquire <path>
# ... write ...
bash scripts/wiki-lock.sh release <path>
```
