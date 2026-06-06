# sovs-brain-skill

Portable tooling that lets any producer host feed its durable footprint into a
**brain**: a plain-text, git-versioned knowledge substrate, without coupling to
any editor or proprietary sync.

Harness-agnostic. Run it from Claude Code, Codex, OpenClaw, Hermes, or a plain
shell. It does three things:

1. **Assess** where this host's agent writes its footprint (identity, memory,
   outputs), across whatever harness it runs.
2. **Sanitize** that into a standard staging directory with a one-way local
   rsync, filtering out secrets, churn, and large files. The live working dirs
   are never modified.
3. **Transport** the clean stage to the brain's main store (one source of truth),
   one-way, with a simple widely-used sync tool.

The brain itself is intentionally dumb: a directory structure, light frontmatter,
and a standard sync tool. All filtering lives here, in the layer on top, never in
the brain.

## Two-hop model

```
agent's live workdir + identity/memory files
  --(hop 1: local rsync, filtered, one-way)-->  ~/.sovs-brain/stage/<host>/
  --(hop 2: Syncthing send-only OR pull rsync)-->  main store: raw/workspaces/<host>/
```

Hop 1 sanitizes locally so the production directory is never shipped directly.
Hop 2 transports the already-clean stage. The stage dir is both the rsync target
and the transport source.

## Quick start

```bash
scripts/assess.sh                 # see what this host writes (read-only)
cp sovs-brain.conf.example sovs-brain.conf
$EDITOR sovs-brain.conf           # set what to capture for this host
scripts/sanitize.sh               # hop 1: build the clean stage
scripts/provision-syncthing.sh    # hop 2 (option A), or see docs/transport-rsync-pull.md
```

## Files
- `SKILL.md` — agent-facing instructions.
- `sovs-brain.conf.example` — per-host capture config (copy to `sovs-brain.conf`).
- `filter.rules` — rsync filter: what never leaves the host.
- `scripts/assess.sh` — read-only footprint assessment.
- `scripts/sanitize.sh` — hop 1, one-way filtered local mirror to the stage dir.
- `scripts/provision-syncthing.sh` — hop 2 option A: Syncthing send-only.
- `docs/transport-rsync-pull.md` — hop 2 option B: main store pulls.

Pilot-grade. Wire one quiet host first, confirm the loop, then roll wider.
