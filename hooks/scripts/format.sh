#!/bin/bash
# PostToolUse hook: run `dart format` on each edited Dart file, never blocking.
# The files come from the arguments, or from the payload when there are none; see
# hook_file_paths in vgv-cli-common.sh.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/vgv-cli-common.sh"

# Only the payload needs jq to read
if [ "$#" -eq 0 ] && ! command -v jq &>/dev/null; then
  echo "format hook: jq not found, skipping" >&2
  exit 0
fi

while IFS= read -r file_path; do
  [[ "$file_path" == *.dart ]] || continue
  dart format "$file_path" &>/dev/null || true
done < <(hook_file_paths "$@")
