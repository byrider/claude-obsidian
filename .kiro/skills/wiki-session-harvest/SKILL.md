---
name: wiki-session-harvest
description: >
  Finds, parses, and ingests past CLI/IDE sessions from Kiro and Claude Code into
  the wiki vault. Discovers session storage locations, extracts conversation content,
  and files valuable sessions as wiki pages with full cross-referencing.
  Triggers on: "harvest sessions", "ingest sessions", "import my sessions",
  "find my sessions", "session harvest", "import chat history",
  "ingest my conversations", "process past sessions".
allowed-tools: Read Write Edit Glob Grep Bash
---

# Wiki Session Harvest — Import CLI/IDE Sessions

Finds past conversations from Kiro IDE, Kiro CLI, and Claude Code, extracts the valuable content, and files them into the wiki vault. Every session you've had becomes searchable, cross-referenced knowledge.

## Supported Sources

| Tool | Storage Location | Format |
|------|-----------------|--------|
| **Kiro IDE** (macOS) | `~/Library/Application Support/Kiro/User/globalStorage/kiro.kiroagent/` | JSON (legacy `.chat` + modern extensionless) |
| **Kiro IDE** (Linux) | `~/.config/Kiro/User/globalStorage/kiro.kiroagent/` | JSON |
| **Kiro IDE** (Windows) | `%APPDATA%/Kiro/User/globalStorage/kiro.kiroagent/` | JSON |
| **Kiro CLI** | `~/.kiro/sessions/cli/{session_id}.json` (metadata) + `{session_id}.jsonl` (conversation) | JSON + append-only JSONL, read directly from disk |
| **Claude Code** | `~/.claude/projects/<project-hash>/<session-id>.jsonl` | Append-only JSONL |

## Discovery

### Step 1: Detect installed tools

```bash
# Kiro IDE
KIRO_IDE_PATH=""
if [ -d "$HOME/Library/Application Support/Kiro/User/globalStorage/kiro.kiroagent" ]; then
  KIRO_IDE_PATH="$HOME/Library/Application Support/Kiro/User/globalStorage/kiro.kiroagent"
elif [ -d "$HOME/.config/Kiro/User/globalStorage/kiro.kiroagent" ]; then
  KIRO_IDE_PATH="$HOME/.config/Kiro/User/globalStorage/kiro.kiroagent"
fi

# Kiro CLI — detect by its session store on disk (more reliable than a binary
# check; the binary may be named `kiro-cli` or `kiro`).
KIRO_CLI_SESSIONS=""
if [ -d "$HOME/.kiro/sessions/cli" ]; then
  KIRO_CLI_SESSIONS="$HOME/.kiro/sessions/cli"
fi

# Claude Code
CLAUDE_PATH=""
if [ -d "$HOME/.claude/projects" ]; then
  CLAUDE_PATH="$HOME/.claude/projects"
fi
```

### Step 2: List available sessions

**Kiro IDE sessions:**
- Scan workspace hash directories under the globalStorage path
- Look for `.chat` files (legacy) and extensionless execution files (modern)
- Skip session index files (`{ executions: [...] }`) — they don't contain conversation content
- Try to resolve workspace names from `workspace.json` or base64-decoded directory names

**Kiro CLI sessions:**

There is no `kiro session list`/`export` command. Sessions are plain files on
disk under `~/.kiro/sessions/cli/`, so discover and read them directly:
- `{session_id}.json` — metadata (cwd, timestamps, title, state)
- `{session_id}.jsonl` — append-only conversation log
- `{session_id}.lock` — present only while a session is active (skip these)

```bash
# Discover CLI sessions (newest first)
find ~/.kiro/sessions/cli -name "*.jsonl" -type f 2>/dev/null | head -50
```

(Interactive commands like `kiro-cli chat --resume`, `/chat save`, and
`/transcript save` exist for live use but are not needed for bulk harvest.)

**Claude Code sessions:**
```bash
# List all project directories and their sessions
find "$HOME/.claude/projects" -name "*.jsonl" -type f 2>/dev/null | head -50
```

### Step 3: Present to user

Show a summary:
```
Found sessions:
  Kiro IDE:    N sessions across M workspaces
  Kiro CLI:    N sessions in current directory (P total across all dirs)
  Claude Code: N sessions across M projects

Options:
  1. Harvest ALL sessions (may be large)
  2. Harvest sessions from last N days
  3. Harvest sessions for a specific project/workspace
  4. Let me pick specific sessions
```

## Parsing

### Kiro IDE Format

**Legacy `.chat` files:**
```json
{
  "chat": [...],
  "metadata": { "model": "...", "timestamp": "..." },
  "executionId": "..."
}
```

**Modern extensionless execution files:**
Look for conversation content in these fields (Kiro changes format occasionally):
- `messages`
- `conversation`
- `chat`
- `transcript`
- `entries`
- `events`
- Direct `prompt` / `response` fields

Extract: user messages, assistant responses, tool calls (both structured and text-envelope `<tool_use><name>...</name>`).

### Kiro CLI Format

Sessions are stored as JSONL files at `~/.kiro/sessions/cli/{session_id}.jsonl`. Each line is a conversation turn. Read the `.jsonl` file directly and parse line-by-line.

Metadata (title, timestamps, cwd) is in the companion `{session_id}.json` file. Skip any session that still has a `{session_id}.lock` file (it is active).

### Claude Code JSONL Format

Each line is a JSON object representing one conversation turn:
```jsonl
{"type":"human","message":{"content":"..."},"timestamp":"..."}
{"type":"assistant","message":{"content":"...","tool_use":[...]},"timestamp":"..."}
{"type":"tool_result","tool_use_id":"...","content":"..."}
```

Parse by reading line-by-line, extracting human messages and assistant responses, ignoring tool_result entries (unless they contain significant output).

## Filtering

Not every session is worth ingesting. Apply these filters:

**Always skip:**
- Sessions under 3 exchanges (too short to have value)
- Sessions that are purely mechanical (e.g., "run npm install" followed by "done")
- Sessions that are exact duplicates of already-ingested content

**Always include:**
- Sessions with architectural decisions
- Sessions with research or analysis
- Sessions where the user explicitly asked to "save" or "remember"
- Sessions longer than 10 exchanges with substantive content

**Ask the user about:**
- Sessions in the middle ground (5-10 exchanges, unclear value)

## Filing

Each valuable session becomes a wiki page:

```yaml
---
type: session
title: "Session: [Brief Topic Summary]"
source_tool: kiro-ide | kiro-cli | claude-code
session_id: "<original session ID>"
workspace: "<workspace name or path>"
date: YYYY-MM-DD
duration_turns: N
created: YYYY-MM-DD
updated: YYYY-MM-DD
tags: [session, tool-name, domain-tag]
status: developing
related:
  - "[[Any Wiki Page Mentioned]]"
---

# Session: [Brief Topic Summary]

## Context
- Tool: [Kiro IDE / Kiro CLI / Claude Code]
- Workspace: [project name]
- Date: [date]
- Turns: [N exchanges]

## Key Insights
- [Most important takeaway from this session]
- [Second insight]
- [Third insight]

## Summary
[3-5 sentence summary of what was discussed and decided]

## Decisions Made
- [Decision 1]: [rationale]
- [Decision 2]: [rationale]

## Entities Mentioned
- [[Entity 1]]: context
- [[Entity 2]]: context

## Concepts Explored
- [[Concept 1]]: key point
- [[Concept 2]]: key point

## Raw Highlights
> [Notable quotes or exchanges worth preserving verbatim]
```

## Batch Processing

When harvesting many sessions:

1. Parse all sessions first, compute value scores
2. Present top-N to user for confirmation
3. Process in batches of 10
4. After each batch: update index, log, hot cache
5. Cross-reference pass at the end (link sessions that discuss the same topics)

## After Filing

1. Update `wiki/index.md` — add entries under Sessions section
2. Append to `wiki/log.md` (at TOP):
   ```
   ## [YYYY-MM-DD] session-harvest | [Tool Name]
   - Sessions found: N
   - Sessions ingested: M
   - Pages created: [[Session 1]], [[Session 2]], ...
   - Key topics: topic1, topic2
   ```
3. Update `wiki/hot.md`
4. Create or update entity/concept pages if new ones were discovered

## Mode Awareness

Route session pages through the mode router:
```bash
python3 scripts/wiki-mode.py route session "<session-topic>"
```
If the router fails or prints nothing, fall back to the generic layout
(`wiki/sessions/`) and continue; never block filing on the router.

## Concurrency

Lock before writing:
```bash
bash scripts/wiki-lock.sh acquire "$NOTE_PATH"
# ... write ...
bash scripts/wiki-lock.sh release "$NOTE_PATH"
```

## Privacy and Secret Redaction (required)

Session transcripts routinely contain credentials, personal data, and internal
references. Redaction is mandatory and happens BEFORE any content is written to a
wiki page, `wiki/log.md`, or `wiki/hot.md`. When in doubt, redact.

### Rule

Replace every match below with `[REDACTED]` (keep the surrounding text so the
session still reads coherently). Never copy an unredacted secret into the vault.
If a "Raw Highlights" block cannot be safely redacted, drop the block entirely and
note `[highlight omitted: contained secrets]`.

### Secret value patterns

- **API keys with known prefixes**: `sk-...`, `sk-ant-...` (Anthropic), `AKIA...`
  (AWS access key id), `ghp_/gho_/ghu_/ghs_/ghr_...` (GitHub), `xoxb-/xoxp-...`
  (Slack), `AIza...` (Google), `glpat-...` (GitLab).
- **Bearer / Authorization tokens**: any `Authorization: Bearer <token>` or
  `bearer <token>` value.
- **JWTs**: three base64url segments separated by dots (`eyJ...` . `...` . `...`).
- **Database connection strings with embedded passwords**: redact the credentials
  portion of `scheme://user:password@host/...` for `postgres`, `postgresql`,
  `mysql`, `mongodb`, `mongodb+srv`, `redis`, `rediss`, `amqp`, `amqps`, `mssql`,
  and similar. Rewrite as `scheme://user:[REDACTED]@host/...`.
- **Private keys**: any PEM block from `-----BEGIN ... PRIVATE KEY-----` through
  `-----END ... PRIVATE KEY-----` (RSA, OpenSSH, EC, DSA, PGP). Replace the whole
  block with `[REDACTED private key]`.
- **Generic high-entropy assignments**: values after `password=`, `passwd=`,
  `secret=`, `token=`, `api_key=`, `apikey=`, `access_key=`, `secret_key=`,
  in URLs, env dumps, and config snippets, even without a recognizable prefix.

### Structured-payload field deny-list

When a transcript contains JSON or YAML, redact the VALUE of any field whose key
(case-insensitive) is one of: `password`, `passwd`, `pwd`, `secret`,
`client_secret`, `token`, `access_token`, `refresh_token`, `id_token`, `api_key`,
`apikey`, `access_key`, `secret_key`, `private_key`, `credentials`, `authorization`,
`auth`, `session_token`, `cookie`, `connection_string`, `dsn`.
Example: `"password": "hunter2"` becomes `"password": "[REDACTED]"`.

### Additional handling

- Flag (do not auto-ingest) sessions that reference private repos, internal
  hostnames, or non-public URLs; ask the user first.
- Ask the user before ingesting sessions from shared or team workspaces.
- Redact personal data (emails, phone numbers, home addresses) unless the user
  has explicitly asked to keep it.
- After redacting, scan the final page text once more for any of the value
  patterns above before writing. The vault is committed to git, so a leaked
  secret is a leaked secret in history.
