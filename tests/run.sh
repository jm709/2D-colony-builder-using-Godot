#!/usr/bin/env bash
set -euo pipefail
GODOT="/mnt/c/Users/macph/Pictures/godot/Godot_v4.5.1-stable_win64.exe/Godot_v4.5.1-stable_win64_console.exe"
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
"$GODOT" --headless --path "$PROJECT_DIR" --script res://tests/run_all.gd "$@"
