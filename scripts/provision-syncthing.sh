#!/usr/bin/env bash
# UNUSED. Hop 2 is rsync (scripts/transport-rsync.sh), not Syncthing.
# Kept as a leftover helper: checks prerequisites and prints pairing steps.
# (Folder add is done via the Syncthing UI/API once, then it runs continuously.)
set -euo pipefail

HERE="$(cd "$(dirname "$0")/.." && pwd)"
CONF="${SOVS_BRAIN_CONF:-$HERE/sovs-brain.conf}"
[ -f "$CONF" ] && { . "$CONF"; } || true
HOST="${HOST:-$(hostname -s)}"
DEST="${STAGE:-$HOME/.sovs-brain/stage}/$HOST"

echo "# sovs-brain hop-2: Syncthing send-only for $DEST"
echo

if ! command -v syncthing >/dev/null 2>&1; then
  echo "Syncthing not installed. Install it (e.g. 'brew install syncthing' or your"
  echo "distro package), start it once to generate a device ID, then re-run."
  exit 1
fi

DEVID="$(syncthing --device-id 2>/dev/null || true)"
echo "This host's Syncthing device ID:"
echo "  ${DEVID:-<start syncthing once to generate it>}"
echo
cat <<EOF
Pairing steps (do once):
  1. On the MAIN STORE host, add this device ID as a remote device.
  2. On THIS host, add a folder:
       - Path:        $DEST
       - Folder type: Send Only            <- one-way guarantee
       - Share with:  <main-store device>
  3. On the MAIN STORE, accept the shared folder and set its type to
     Receive Only, pointing at: raw/workspaces/$HOST/
  4. For fully-local operation: in Settings, disable Global Discovery and
     Relaying, and pin each device's address to a private IP.

Verify: edits in $DEST appear under raw/workspaces/$HOST/ on the main store,
and nothing ever flows back to this host.
EOF
