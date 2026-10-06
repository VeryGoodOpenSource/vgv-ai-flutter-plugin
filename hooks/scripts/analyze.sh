#!/bin/bash
# PostToolUse hook: run `dart analyze` on each edited Dart file and block on any issue.
# The files come from the arguments, or from the payload when there are none; see
# hook_file_paths in vgv-cli-common.sh.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/vgv-cli-common.sh"

# Only the payload needs jq to read
if [ "$#" -eq 0 ] && ! command -v jq &>/dev/null; then
  echo "analyze hook: jq not found, skipping" >&2
  exit 0
fi

# Analyze every Dart file, so one run reports every issue, then block if any failed
status=0
while IFS= read -r file_path; do
  [[ "$file_path" == *.dart ]] || continue
  output=$(dart analyze "$file_path" 2>&1) || {
    echo "$output" >&2
    status=2
  }
done < <(hook_file_paths "$@")
exit "$status"
