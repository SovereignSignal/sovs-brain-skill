#!/usr/bin/env bash
# sovs-brain: assess this host's agent footprint. Read-only. Prints a manifest.
set -euo pipefail

HOST="$(hostname -s 2>/dev/null || hostname)"
echo "# sovs-brain footprint assessment: $HOST"
echo

echo "## Harness workspace dirs"
found_harness=0
for d in \
  "$HOME/.openclaw/workspace" \
  "$HOME/.hermes" \
  "$HOME/.claude" \
  "$HOME/.codex" \
  "$HOME/.cursor" \
  "$HOME/Documents/Claude" \
  "$HOME/Documents/Codex" \
  "$HOME/Documents/Cursor"
do
  if [ -d "$d" ]; then
    echo "  found: $d ($(du -sh "$d" 2>/dev/null | cut -f1))"
    found_harness=1
  fi
done
[ "$found_harness" = 0 ] && echo "  (none of the common harness dirs found)"

echo
echo "## Identity / memory files (common locations)"
NAMES=(SOUL.md AGENTS.md IDENTITY.md USER.md HEARTBEAT.md TOOLS.md MEMORY.md)
SEARCH=(
  "$PWD" "$HOME"
  "$HOME/.openclaw/workspace" "$HOME/.hermes" "$HOME/.claude" "$HOME/.codex"
  "$HOME/.cursor" "$HOME/Documents/Claude" "$HOME/Documents/Codex" "$HOME/Documents/Cursor"
)
seen=""
for base in "${SEARCH[@]}"; do
  [ -d "$base" ] || continue
  for n in "${NAMES[@]}"; do
    f="$base/$n"
    if [ -f "$f" ] && [[ "$seen" != *"|$f|"* ]]; then
      seen="$seen|$f|"
      flag=""
      [ "$n" = "TOOLS.md" ] && flag="   <- host-local, do NOT ship"
      echo "  $f$flag"
    fi
  done
  [ -d "$base/.remember" ] && echo "  $base/.remember/ ($(ls -1 "$base/.remember" 2>/dev/null | wc -l | tr -d ' ') files; ship durable bits only)"
done

echo
echo "## Next"
echo "  cp sovs-brain.conf.example sovs-brain.conf  &&  edit it to match the above,"
echo "  then run scripts/sanitize.sh. Secrets and TOOLS.md must stay out."
