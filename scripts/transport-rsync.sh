#!/usr/bin/env bash
# Hop 2. One-way rsync of the clean stage into the brain lane.
#   rsync -a --delete --max-delete=N  stage/<host>/  <brain>/<lane>/
# Never writes the producer's live harness dirs. The brain is the dest only.
set -euo pipefail

HERE="$(cd "$(dirname "$0")/.." && pwd)"
CONF="${SOVS_BRAIN_CONF:-$HERE/sovs-brain.conf}"
[ -f "$CONF" ] || { echo "missing config: $CONF (copy sovs-brain.conf.example)"; exit 1; }
# shellcheck source=/dev/null
source "$CONF"

HOST="${HOST:-$(hostname -s)}"
SRC="${STAGE:-$HOME/.sovs-brain/stage}/$HOST/"
LANE="${LANE:-raw/workspaces/$HOST}"
MAX_DELETE="${MAX_DELETE:-20}"

[ -n "${BRAIN:-}" ] || { echo "set BRAIN to the vault root in $CONF"; exit 1; }
[ -d "${SRC%/}" ] || { echo "missing stage: $SRC — run scripts/sanitize.sh first"; exit 1; }

DEST="$BRAIN/$LANE"
mkdir -p "$DEST"

echo "# transport $SRC -> $DEST/"
rsync -a --delete --max-delete="$MAX_DELETE" "$SRC" "$DEST/"

echo
echo "# lane contents:"
n=0
while IFS= read -r f; do
  n=$((n + 1))
  [ "$n" -le 100 ] && echo "  ${f#"$DEST/"}"
done < <(find "$DEST" -type f 2>/dev/null | sort)
echo "  ($n files)"
echo
echo "That is the host's lane on the brain. One-way: nothing flows back to the stage or harness."
