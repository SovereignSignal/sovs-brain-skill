#!/usr/bin/env bash
# sovs-brain: hop 1. One-way, filtered local mirror of footprint -> stage dir.
# Reads sovs-brain.conf. Does NOT modify any source path. Idempotent.
set -euo pipefail

HERE="$(cd "$(dirname "$0")/.." && pwd)"
CONF="${SOVS_BRAIN_CONF:-$HERE/sovs-brain.conf}"
FILTER="$HERE/filter.rules"
[ -f "$CONF" ] || { echo "missing config: $CONF (copy sovs-brain.conf.example)"; exit 1; }
# shellcheck source=/dev/null
source "$CONF"

HOST="${HOST:-$(hostname -s)}"
DEST="${STAGE:-$HOME/.sovs-brain/stage}/$HOST"
mkdir -p "$DEST/identity" "$DEST/memory" "$DEST/output"

stage_one() {  # <src> <subdir>
  local src="$1" sub="$2"
  [ -e "$src" ] || { echo "  skip (missing): $src"; return 0; }
  rsync -a --prune-empty-dirs \
        --filter=". $FILTER" \
        --max-size="${MAX_SIZE:-25m}" \
        "$src" "$DEST/$sub/"
  echo "  rsync: $src -> $sub/  (filter may drop the file; check stage listing)"
}

echo "# sanitize -> $DEST"
for f in "${IDENTITY_FILES[@]:-}"; do [ -n "${f:-}" ] && stage_one "$f" identity; done
for p in "${MEMORY_PATHS[@]:-}";   do [ -n "${p:-}" ] && stage_one "$p" memory;   done
for o in "${OUTPUT_DIRS[@]:-}";    do [ -n "${o:-}" ] && stage_one "$o" output;   done

echo
echo "# stage contents:"
n=0
while IFS= read -r f; do
  n=$((n + 1))
  [ "$n" -le 100 ] && echo "  ${f#"$DEST/"}"
done < <(find "$DEST" -type f 2>/dev/null | sort)
echo "  ($n files)"
echo
echo "Review the above. That is exactly what hop 2 will transport to the main store."
