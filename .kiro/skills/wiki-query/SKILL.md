---
name: wiki-query
description: >
  Answers questions using the Obsidian wiki vault. Reads hot cache first, then index,
  then relevant pages. Synthesizes answers with citations. Files good answers back
  as wiki pages.
  Triggers on: "what do you know about [X]", "query: [question]", "what is [X]",
  "explain [X]", "summarize [X]", "find in wiki", "search the wiki".
allowed-tools: Read Write Edit Glob Grep Bash
---

# Wiki Query — Answer Questions from the Vault

The wiki has already done the synthesis work. Read strategically, answer precisely, cite sources, and file good answers back so knowledge compounds.

## Query Modes

| Mode | Trigger | Reads | Best for |
|------|---------|-------|----------|
| **Quick** | "query quick: ..." or simple factual Q | hot.md + index.md only | "What is X?", date lookups |
| **Standard** | default | hot.md + index + 3-5 pages | Most questions |
| **Deep** | "query deep: ..." or "comprehensive" | Full wiki + optional web | Synthesis, comparisons |

## Quick Mode

1. Read `wiki/hot.md`. If it answers the question, respond immediately.
2. If not, read `wiki/index.md`. Scan for the answer.
3. If not found: "Not in quick cache. Run as standard query?"

Do NOT open individual wiki pages in quick mode.

## Standard Query Workflow

1. **Read** `wiki/hot.md` first
2. **Read** `wiki/index.md` to find relevant pages
3. **Read** those pages (max 3-5). Follow wikilinks to depth-2
4. **Synthesize** the answer with citations: `(Source: [[Page Name]])`
5. **Offer to file**: "Should I save this as a wiki page?"
6. If a **gap** is found: "I don't have enough on X. Want to find a source?"

## Deep Mode

1. Read hot.md and index.md
2. Identify ALL relevant sections
3. Read every relevant page — no skipping
4. Offer to supplement with web search if coverage is thin
5. Synthesize comprehensive answer with full citations
6. Always file the result back as a wiki page

## Hybrid Retrieval (if provisioned)

If `scripts/retrieve.py` exists and BM25 index is built:
```bash
python3 scripts/retrieve.py "<question>" --top 5
```
Use returned candidates before the legacy hot→index→drill chain.

## Token Discipline

| Start with | When to stop |
|------------|--------------|
| hot.md (~500 tokens) | If it has the answer |
| index.md (~1000 tokens) | If you can identify pages |
| 3-5 wiki pages (~300 each) | Usually sufficient |
| 10+ pages | Only for full-wiki synthesis |

## Filing Answers Back

Good answers compound into the wiki. When filing:

```yaml
---
type: question
title: "Short descriptive title"
question: "The exact query as asked."
answer_quality: solid
created: YYYY-MM-DD
updated: YYYY-MM-DD
tags: [question, domain-tag]
related:
  - "[[Referenced Page]]"
status: developing
---
```

After filing: update `wiki/index.md` under Questions, append to `wiki/log.md`.

## Gap Handling

If the question cannot be answered from the wiki:
1. Say clearly: "I don't have enough in the wiki to answer this."
2. Identify the specific gap
3. Suggest: "Want to find a source on this?"
4. Do NOT fabricate from training data for domain-specific questions
