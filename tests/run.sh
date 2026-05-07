#!/usr/bin/env bash
set -euo pipefail
GODOT="/mnt/c/Users/macph/Pictures/godot/Godot_v4.5.1-stable_win64.exe/Godot_v4.5.1-stable_win64_console.exe"
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
if [ ! -d "$PROJECT_DIR/.godot" ]; then
	"$GODOT" --headless --path "$PROJECT_DIR" --import
fi

# Capture output so we can parse it (Godot's exit code can't be trusted — past
# versions exit 0 even on parse errors and explicit tree.quit(1) calls). The
# Windows console binary writes CRLF line endings under WSL, so strip CRs
# before matching. Disable pipefail/errexit for the capture so a non-zero
# Godot exit doesn't abort before we can echo and parse the output.
set +e
output=$("$GODOT" --headless --path "$PROJECT_DIR" --script res://tests/run_all.gd "$@" 2>&1 | tr -d '\r')
set -e
echo "$output"

# Require the summary line; fail if any assertion failed or summary is missing.
if ! echo "$output" | grep -qE '^[0-9]+ passed, [0-9]+ failed$'; then
	echo "ERROR: test runner did not print summary line" >&2
	exit 2
fi
if echo "$output" | grep -qE '^[0-9]+ passed, 0 failed$'; then
	exit 0
fi
exit 1
