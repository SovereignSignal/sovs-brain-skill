---
name: sovs-brain
description: Connect a producer host to the sovs-brain knowledge store. Use when onboarding a host or agent to the brain, "set up brain sync here", "connect this box to the brain", or standardizing how an agent's SOUL/AGENTS/IDENTITY/MEMORY and work outputs get captured to the main vault. Harness-agnostic (Cursor, Claude Code, Codex, OpenClaw, Hermes). Sets up a one-way local sanitize plus one-way rsync to the single main store; never modifies the agent's live working dirs. Do not use Syncthing.
---

# sovs-brain producer feed

Goal: get this host feeding its durable footprint into the brain's main store,
one-way and sanitized, using rsync. Never touch the agent's live working
directories; never ship secrets.

## The shape

Two hops. Both are rsync. Hop 1 is local sanitize. Hop 2 is the vault write.

```
live footprint --hop1 rsync--> ~/.sovs-brain/stage/<host>/ --hop2 rsync--> <brain>/<lane>/
```

Default Cursor lane: `raw/tools/Cursor/<host>/`. VM producers use
`raw/workspaces/<name>/` instead.

## Steps

1. **Assess (read-only).** Run `scripts/assess.sh`. It reports the harness dirs
   present (`~/.cursor`, `~/Documents/Cursor`, `~/.openclaw/workspace`,
   `~/.hermes`, `~/.claude`, `~/.codex`, `~/Documents/Claude`, `~/Documents/Codex`)
   and the identity and memory files it finds (`SOUL.md`, `AGENTS.md`,
   `IDENTITY.md`, `USER.md`, `HEARTBEAT.md`, `MEMORY.md`, `.remember/`). Read
   the manifest before changing anything. Cursor Cloud / desktop often has
   **no** SOUL/MEMORY files — only capture finished notes you explicitly list.

2. **Configure.** `cp sovs-brain.conf.example sovs-brain.conf` and edit it for
   this host: list the identity files, memory paths, and output dirs to capture,
   plus `BRAIN` (vault root) and `LANE`. Leave `TOOLS.md`, `.env`, keys, and
   any secrets out. Do not point `OUTPUT_DIRS` at `~/.cursor` (plugins,
   terminals, MCP). `filter.rules` is the backstop that drops them even if
   mis-listed.

3. **Sanitize (hop 1).** Run `scripts/sanitize.sh`. It one-way rsyncs the
   configured sources into `~/.sovs-brain/stage/<host>/{identity,memory,output}/`,
   applying `filter.rules` and a size cap. Source dirs are read, never written.
   Inspect the stage; it is exactly what will leave this host.

4. **Transport (hop 2).** Run `scripts/transport-rsync.sh`. It rsyncs the stage
   into `$BRAIN/$LANE` with `--delete` and `--max-delete`. One-way: the brain
   is destination only.
   If this host should not touch the vault, omit `BRAIN` and let the main store
   pull — see `docs/transport-rsync-pull.md`.

5. **Verify.** Confirm the host's lane appears under the configured `LANE` on
   the main store, contains only sanitized content, and that nothing flows back
   toward this host (one-way). `scripts/selftest.sh` proves the loop against a
   mock vault.

## Rules

- One-way only. The brain never writes back into a harness dir.
- The main store is the single committer to git. Producers never commit.
- Re-run `sanitize.sh` then `transport-rsync.sh` on a schedule to refresh.
- If unsure whether a file is sensitive, exclude it.
- Do not use Syncthing. Hop 2 is rsync.
