#!/bin/bash
set -euo pipefail

# Read the hook payload from stdin
input=$(cat)

# Check jq availability
if ! command -v jq &>/dev/null; then
  echo "format hook: jq not found, skipping" >&2
  exit 0
fi

# Extract file path from the tool input
file_path=$(jq -r '.tool_input.file_path // empty' <<< "$input")

# Skip if no file path or not a Dart file
if [[ -z "$file_path" || "$file_path" != *.dart ]]; then
  exit 0
fi

# Run dart format on the single file (auto-fix, always exit 0)
dart format "$file_path" &>/dev/null || true