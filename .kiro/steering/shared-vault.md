# Shared Vault Across Kiro Surfaces

This vault is meant to be used as ONE knowledge base from three Kiro surfaces: local
IDE, local CLI, and Web (cloud sandbox). They do not share a filesystem, so git is the
single source of truth and the sync substrate. Follow these rules to keep the vault
consistent and avoid conflicts.

## Mental model

- Local IDE and local CLI run on your machine and operate on the SAME folder live. The
  Obsidian app opens that same folder. Edits there are real time.
- Web runs in an ephemeral cloud sandbox. It clones the repo, works, and pushes. It
  cannot see your local disk and its filesystem is thrown away after the session.
- Therefore "shared" means eventually consistent through git pull and push, not a live
  shared drive. Real time sharing exists only between the two local surfaces.

## Transport per surface

Each surface auto-detects its write transport via `scripts/detect-transport.sh`, which
writes a host-specific `.vault-meta/transport.json` (gitignored, never shared):

| Surface | Preferred transport | Notes |
|---------|--------------------|-------|
| Local IDE | Obsidian CLI or MCP | shares the live folder with the Obsidian app |
| Local CLI | same folder as IDE | true real time share with the IDE |
| Web | `filesystem` floor | no Obsidian app and no MCP in the sandbox; uses Kiro Read/Write/Edit |

Do not commit `.vault-meta/transport.json`. It is per host by design.

## Sync protocol (required)

### Local IDE and CLI

1. Pull before you start: `git pull --rebase`.
2. Work normally. Auto-commit is opt-in (see below) or commit by hand.
3. Push when you finish a unit of work: `git push`.
4. If the IDE and CLI are editing at the same time on one machine they share the folder,
   so no git step is needed between them. Push only coordinates with Web and other hosts.

### Web (sandbox)

1. Always work on a branch, never on `main`. Branch from the latest `main`.
2. Never push directly to `main` and never enable auto-commit here (see below).
3. When done, push the branch and open a pull request for review and merge.
4. Treat the sandbox as disposable: nothing is saved unless it is pushed.

### Conflict avoidance

- Do not edit the vault from a local surface and Web at the same moment. Land one,
  pull, then start the other.
- High-churn files (`wiki/index.md`, `wiki/log.md`) are the usual conflict points.
  `wiki/log.md` is append-at-top: on conflict, keep both blocks newest first.
- `wiki/hot.md` is a per-host regenerable cache and is gitignored. Never commit it and
  never resolve conflicts on it; regenerate it locally instead.

## Auto-commit is opt-in and local-only

The `auto-commit-wiki` hook only commits when the host-specific sentinel
`.vault-meta/auto-commit.enabled` exists. That file is gitignored, so:

- It is OFF everywhere by default, including every Web sandbox.
- Enable it on a trusted local machine only: `touch .vault-meta/auto-commit.enabled`.
- The hook also still honors the `.vault-meta/auto-commit.disabled` kill switch and the
  advisory lock check, and it does NOT auto-commit `.raw/` (sources are committed
  deliberately to avoid leaking secrets dropped into `.raw/`).

On Web, leave auto-commit off and use the branch plus pull request flow instead.

## Cross-project reference

To read this vault from a different project, add to that project's steering:

```
When you need context not in this project:
1. Read wiki/index.md (the master catalog)
2. Then drill into specific wiki pages by wikilink
```

Do not point another project at `wiki/hot.md`; it is host-specific and may be absent.
