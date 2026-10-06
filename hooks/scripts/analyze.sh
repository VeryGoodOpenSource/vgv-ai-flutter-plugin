#!/bin/bash
set -euo pipefail

# Read the hook payload from stdin
input=$(cat)

# Check jq availability
if ! command -v jq &>/dev/null; then
  echo "analyze hook: jq not found, skipping" >&2
  exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/vgv-cli-common.sh"

# Run dart analyze on each modified Dart file. A failure on any file blocks, but every
# file is still analyzed so the agent sees all of the issues at once.
status=0
while IFS= read -r file_path; do
  [[ "$file_path" == *.dart ]] || continue
  output=$(dart analyze "$file_path" 2>&1) || {
    echo "$output" >&2
    status=2
  }
done < <(payload_file_paths <<< "$input")

exit "$status"
