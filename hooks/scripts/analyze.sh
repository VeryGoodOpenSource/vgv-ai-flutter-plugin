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
# shellcheck source=hooks/scripts/hook-payload-common.sh
source "$SCRIPT_DIR/hook-payload-common.sh"

# Collect the Dart files this edit touched. Claude Code reports one `file_path`;
# Codex reports an apply_patch envelope that may cover several files.
files=()
while IFS= read -r file; do
  if [ -n "$file" ]; then
    files+=("$file")
  fi
done < <(changed_dart_files "$input")

# Nothing Dart in this edit
if [ ${#files[@]} -eq 0 ]; then
  exit 0
fi

# Run dart analyze on the changed files
output=$(dart analyze "${files[@]}" 2>&1) || {
  echo "$output" >&2
  exit 2
}
