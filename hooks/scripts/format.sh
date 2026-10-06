#!/bin/bash
set -euo pipefail

# Read the hook payload from stdin
input=$(cat)

# Check jq availability
if ! command -v jq &>/dev/null; then
  echo "format hook: jq not found, skipping" >&2
  exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/vgv-cli-common.sh"

# Run dart format on each modified Dart file (auto-fix, always exit 0)
while IFS= read -r file_path; do
  [[ "$file_path" == *.dart ]] || continue
  dart format "$file_path" &>/dev/null || true
done < <(payload_file_paths <<< "$input")
