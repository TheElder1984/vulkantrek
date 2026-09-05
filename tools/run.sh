#!/usr/bin/env bash
set -euo pipefail
project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
if [[ -n "${GODOT_BIN:-}" ]]; then
  engine="$GODOT_BIN"
elif command -v godot4 >/dev/null 2>&1; then
  engine="$(command -v godot4)"
elif command -v godot >/dev/null 2>&1; then
  engine="$(command -v godot)"
elif [[ -x /tmp/godot/Godot_v4.5.1-stable_linux.x86_64 ]]; then
  engine=/tmp/godot/Godot_v4.5.1-stable_linux.x86_64
else
  echo 'Godot 4.5+ is required. Set GODOT_BIN to the engine executable.' >&2
  exit 1
fi
exec "$engine" --path "$project_dir" "$@"
