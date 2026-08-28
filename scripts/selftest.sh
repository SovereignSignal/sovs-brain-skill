#!/usr/bin/env bash
# Prove hop 1 + hop 2 for a Cursor-shaped host, without Syncthing.
# Builds a fixture, sanitizes, transports into a mock brain, checks the lane.
set -euo pipefail

HERE="$(cd "$(dirname "$0")/.." && pwd)"
ROOT="${TMPDIR:-/tmp}/sovs-brain-selftest-$$"
FIX="$ROOT/cursor-home"
STAGE="$ROOT/stage"
BRAIN="$ROOT/brain"
CONF="$ROOT/sovs-brain.conf"
fail=0

cleanup() { rm -rf "$ROOT"; }
trap cleanup EXIT

mkdir -p \
  "$FIX/.cursor" \
  "$FIX/Documents/Cursor/finished" \
  "$FIX/Documents/Cursor/secrets-should-die" \
  "$BRAIN/raw/tools/Cursor/testhost"

# Durable Cursor-shaped footprint
printf 'project agents\n' > "$FIX/Documents/Cursor/AGENTS.md"
printf 'durable identity\n' > "$FIX/Documents/Cursor/IDENTITY.md"
printf 'lesson from a finished run\n' > "$FIX/Documents/Cursor/finished/report.md"
printf 'nested ok\n' > "$FIX/Documents/Cursor/finished/notes.md"

# Must never leave the host
printf 'TOOLS secrets\n' > "$FIX/Documents/Cursor/TOOLS.md"
printf 'API_KEY=abc\n' > "$FIX/Documents/Cursor/.env"
printf 'now churn\n' > "$FIX/Documents/Cursor/now.md"
printf 'zip\n' > "$FIX/Documents/Cursor/finished/bundle.zip"
printf 'token notes\n' > "$FIX/Documents/Cursor/finished/api-token-notes.md"
printf 'AWS_SECRET_ACCESS_KEY=xyz\n' > "$FIX/Documents/Cursor/finished/plain-notes.md"

# Snapshot sources
src_sha=$(find "$FIX" -type f -print0 | sort -z | xargs -0 sha256sum)

cat > "$CONF" <<EOF
HOST="testhost"
STAGE="$STAGE"
MAX_SIZE="25m"
BRAIN="$BRAIN"
LANE="raw/tools/Cursor/testhost"
MAX_DELETE="50"
IDENTITY_FILES=(
  "$FIX/Documents/Cursor/AGENTS.md"
  "$FIX/Documents/Cursor/IDENTITY.md"
  "$FIX/Documents/Cursor/TOOLS.md"
)
MEMORY_PATHS=()
OUTPUT_DIRS=(
  "$FIX/Documents/Cursor/finished/"
)
EOF

export SOVS_BRAIN_CONF="$CONF"
"$HERE/scripts/sanitize.sh" >/tmp/sovs-selftest-sanitize.out
"$HERE/scripts/transport-rsync.sh" >/tmp/sovs-selftest-transport.out

LANE_DIR="$BRAIN/raw/tools/Cursor/testhost"
after_sha=$(find "$FIX" -type f -print0 | sort -z | xargs -0 sha256sum)
if [ "$src_sha" != "$after_sha" ]; then
  echo "FAIL: source files were modified"
  fail=1
fi

present() { [ -f "$LANE_DIR/$1" ] || { echo "FAIL: missing $1"; fail=1; }; }

present "identity/AGENTS.md"
present "identity/IDENTITY.md"
present "output/report.md"
present "output/notes.md"
present "output/plain-notes.md"   # name-only filter; content secrets are a known limit

[ ! -f "$LANE_DIR/identity/TOOLS.md" ] || { echo "FAIL: TOOLS.md leaked"; fail=1; }
[ ! -f "$LANE_DIR/output/bundle.zip" ] || { echo "FAIL: zip leaked"; fail=1; }
[ ! -f "$LANE_DIR/output/api-token-notes.md" ] || { echo "FAIL: *token* leaked"; fail=1; }
[ ! -f "$FIX/Documents/Cursor/.env" ] || true
find "$LANE_DIR" -name '.env' -o -name 'now.md' -o -name 'TOOLS.md' | grep -q . \
  && { echo "FAIL: filtered name reached the brain"; fail=1; } || true

# Hop 2 --delete: a leftover in the lane must vanish once the stage no longer has it
printf 'ghost\n' > "$LANE_DIR/STALE.md"
"$HERE/scripts/transport-rsync.sh" >/tmp/sovs-selftest-transport2.out
if [ -f "$LANE_DIR/STALE.md" ]; then
  echo "FAIL: hop 2 did not delete stale lane file"
  fail=1
fi

# Nothing flows back: editing the lane must not change the fixture
printf 'tamper\n' > "$LANE_DIR/output/report.md"
after2=$(find "$FIX" -type f -print0 | sort -z | xargs -0 sha256sum)
if [ "$src_sha" != "$after2" ]; then
  echo "FAIL: brain-side edit flowed back to the Cursor source"
  fail=1
fi

if [ "$fail" -ne 0 ]; then
  echo
  echo "sanitize log:"; cat /tmp/sovs-selftest-sanitize.out
  echo "transport log:"; cat /tmp/sovs-selftest-transport.out
  echo "lane:"; find "$LANE_DIR" -type f | sort
  exit 1
fi

echo "PASS: Cursor fixture -> stage -> $LANE_DIR"
echo "  identity + finished notes landed"
echo "  TOOLS.md / .env / now.md / zip / *token* stayed off the brain"
echo "  hop 2 --delete cleared a stale lane file"
echo "  source Cursor files were never written"
echo "  a brain-side edit did not flow back"
