# Hop 2, option B: main store pulls

Use this instead of Syncthing if you would rather not run a daemon on each
producer. The main store reaches out on a schedule and pulls each host's stage.
The producer runs no transport at all; it only keeps its local stage fresh
(`scripts/sanitize.sh`).

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

`rrsync` (ships with rsync) confines the key to read-only rsync under that path.

## Main store side (scheduled)

```
# pull each producer's stage into its lane, one-way
rsync -az --delete \
  -e "ssh -i ~/.ssh/sovs-brain-pull" \
  <host>:.sovs-brain/stage/<host>/ \
  "<brain>/raw/workspaces/<host>/"
```

Then the main store commits `raw/workspaces/*` to the brain's git remote. Single
committer, no conflicts. Run from cron/launchd once the manual run is proven.

## Notes

- Over Tailscale, target the producer's tailnet name/IP so it stays local.
- `--delete` keeps the lane an exact mirror of the producer's stage; it only ever
  affects that host's own lane.
