# Hop 2 alternate: main store pulls

Use this instead of `scripts/transport-rsync.sh` when the producer must not
reach the vault (no `BRAIN` path, no inbound surface on the main store). The
producer only keeps its local stage fresh (`scripts/sanitize.sh`). The main
store reaches out on a schedule and pulls.

## Why pull (not push)

The producer never connects into the main store, so the main store keeps zero
inbound surface. The main store initiates every transfer and stays in control of
timing. The producer only needs to allow the main store's key, read-only, scoped
to its stage dir.

## Producer side (once)

Allow the main store's public key, restricted to read-only rsync of the stage:

```
# ~/.ssh/authorized_keys on the producer
command="rrsync -ro ~/.sovs-brain/stage",no-pty,no-agent-forwarding,no-port-forwarding ssh-ed25519 AAAA... mainstore
```

`rrsync` (ships with rsync) chdirs into that jail. The path the client asks for
is relative to `~/.sovs-brain/stage`, not to the producer's home.

## Main store side (scheduled)

```
# pull each producer's stage into its lane, one-way
# rrsync jail is ~/.sovs-brain/stage, so the remote path is <host>/ not
# .sovs-brain/stage/<host>/
rsync -az --delete --max-delete=20 \
  -e "ssh -i ~/.ssh/sovs-brain-pull" \
  <host>:<host>/ \
  "<brain>/raw/tools/Cursor/<host>/"
```

Then the main store commits that lane to the brain's git remote. Single
committer, no conflicts. Run from cron or an equivalent scheduler once the
manual run is proven.

## Notes

- Prefer a private address for the producer so the pull stays off the public
  internet.
- `--delete` keeps the lane an exact mirror of the producer's stage; it only ever
  affects that host's own lane.
- `--max-delete` is a catastrophe brake if the stage is accidentally emptied.
- `rrsync -ro` disables server-side delete options; client `--delete` still
  removes extras on the **destination** (the brain lane), which is what we want.
