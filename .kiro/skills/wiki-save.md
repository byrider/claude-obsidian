# Wiki Save — File Conversations Into the Wiki

## Description
Saves the current conversation, answer, or insight into the Obsidian wiki vault as a structured note. Analyzes the chat, determines the right note type, creates frontmatter, and files it in the correct wiki folder.

## Triggers
- "/save"
- "/save [name]"
- "save this"
- "save that answer"
- "file this"
- "save to wiki"
- "file this conversation"
- "keep this"
- "save this analysis"

## Instructions

Good answers and insights shouldn't disappear into chat history. Take what was discussed and file it as a permanent wiki page. The wiki compounds. Save often.

### Note Type Decision

| Type | Folder | Use when |
|------|--------|---------|
| synthesis | wiki/questions/ | Multi-step analysis, comparison, answer to a question |
| concept | wiki/concepts/ | Explaining or defining an idea, pattern, framework |
| source | wiki/sources/ | Summary of external material discussed |
| decision | wiki/meta/ | Architectural, project, or strategic decision made |
| session | wiki/sessions/ | Full session summary |

If the user specifies a type, use that. Otherwise, pick the best fit. When in doubt, use `synthesis`.

### Mode Awareness

Before creating the note, consult the mode router:
```bash
python3 scripts/wiki-mode.py route session "<topic-summary>"
```

### Save Workflow

1. **Scan** the current conversation — identify the most valuable content
2. **Ask** (if not already named): "What should I call this note?"
3. **Determine** note type from the table above
4. **Extract** all relevant content — rewrite in declarative present tense
5. **Create** the note with full frontmatter
6. **Collect links** — identify any wiki pages mentioned, add to `related`
7. **Update** `wiki/index.md` — add entry in the relevant section
8. **Append** to `wiki/log.md` (new entry at TOP):
   ```
   ## [YYYY-MM-DD] save | Note Title
   - Type: [note type]
   - Location: wiki/[folder]/Note Title.md
   - From: conversation on [brief topic]
   ```
9. **Update** `wiki/hot.md` to reflect the addition
10. **Confirm**: "Saved as [[Note Title]] in wiki/[folder]/."

### Writing Style

- Declarative, present tense — write the knowledge, not the conversation
- NOT: "The user asked about X and Kiro explained..."
- YES: "X works by doing Y. The key insight is Z."
- Include all relevant context — future sessions should read this page cold
- Link every mentioned concept/entity with wikilinks
- Cite sources: `(Source: [[Page]])`

### What to Save vs. Skip

**Save:**
- Non-obvious insights or synthesis
- Decisions with rationale
- Analyses that took significant effort
- Research findings

**Skip:**
- Mechanical Q&A with obvious answers
- Setup steps already documented elsewhere
- Temporary debugging with no lasting insight
- Anything already in the wiki (update existing page instead)

### Frontmatter Template

```yaml
---
type: <synthesis|concept|source|decision|session>
title: "Note Title"
created: YYYY-MM-DD
updated: YYYY-MM-DD
tags:
  - <relevant-tag>
status: developing
related:
  - "[[Any Wiki Page Mentioned]]"
---
```

### Concurrency

Lock before writing:
```bash
bash scripts/wiki-lock.sh acquire "$NOTE_PATH"
# ... write ...
bash scripts/wiki-lock.sh release "$NOTE_PATH"
```
