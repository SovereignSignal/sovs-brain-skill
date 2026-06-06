---
name: sovs-brain
description: Connect a producer host to the sovs-brain knowledge store. Use when onboarding a host or agent to the brain, "set up brain sync here", "connect this box to the brain", or standardizing how an agent's SOUL/AGENTS/IDENTITY/MEMORY and work outputs get captured to the main vault. Harness-agnostic (Claude Code, Codex, OpenClaw, Hermes). Sets up a one-way local sanitize plus one-way transport to the single main store; never modifies the agent's live working dirs.
---

# sovs-brain producer feed

Goal: get this host feeding its durable footprint into the brain's main store,
one-way and sanitized, using simple widely-used tools. Never touch the agent's
live working directories; never ship secrets.

## The shape

Two hops. Hop 1 is settled (local rsync sanitize). Hop 2 is one of two transports.

```
live footprint --hop1 rsync--> ~/.sovs-brain/stage/<host>/ --hop2--> main store raw/workspaces/<host>/
```

## Steps

1. **Assess (read-only).** Run `scripts/assess.sh`. It reports the harness dirs
   present (`~/.openclaw/workspace`, `~/.hermes`, `~/.claude`) and the identity and
   memory files it finds (`SOUL.md`, `AGENTS.md`, `IDENTITY.md`, `USER.md`,
   `HEARTBEAT.md`, `MEMORY.md`, `.remember/`). Read the manifest before changing
   anything.

2. **Configure.** `cp sovs-brain.conf.example sovs-brain.conf` and edit it for
   this host: list the identity files, memory paths, and output dirs to capture.
   Leave `TOOLS.md`, `.env`, keys, and any secrets out. `filter.rules` is the
   backstop that drops them even if mis-listed.

3. **Sanitize (hop 1).** Run `scripts/sanitize.sh`. It one-way rsyncs the
   configured sources into `~/.sovs-brain/stage/<host>/{identity,memory,output}/`,
   applying `filter.rules` and a size cap. Source dirs are read, never written.
   Inspect the stage; it is exactly what will leave this host.

4. **Transport (hop 2).** Pick one:
   - **A. Syncthing (recommended):** `scripts/provision-syncthing.sh`. Shares the
     stage dir as a **send-only** folder; the main store holds the matching
     **receive-only** folder. Continuous, one-way, no inbound surface on the main
     store. Pin to private addresses (e.g. Tailscale) with discovery/relay off to
     stay fully local.
   - **B. Pull rsync:** the main store reaches out and pulls the stage on a
     schedule. No daemon here. See `docs/transport-rsync-pull.md`.

5. **Verify.** Confirm the host's lane appears under `raw/workspaces/<host>/` on
   the main store, contains only sanitized content, and that nothing flows back
   toward this host (one-way).

## Rules

- One-way only. The brain never writes back into a harness dir.
- The main store is the single committer to git. Producers never commit.
- Re-run `sanitize.sh` (cron or on change) to refresh; it is idempotent.
- If unsure whether a file is sensitive, exclude it.
