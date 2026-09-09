#!/bin/bash
set -euo pipefail

# Read the hook payload from stdin
input=$(cat)

# Check jq availability
if ! command -v jq &>/dev/null; then
  echo "analyze hook: jq not found, skipping" >&2
  exit 0
fi

# Which files did this edit touch? The two harnesses answer differently:
#
#   Claude Code  Edit / Write  ->  .tool_input.file_path (one path)
#   Codex        apply_patch   ->  .tool_input.command (a patch envelope, no path)
#
# Codex hook payloads carry no file path and no changed-file list, so the paths
# are read out of the patch headers. A rename emits both the old and the new
# path; the old one no longer exists, so the -f test below drops it. Deleted
# files never match, since only Add/Update/Move headers are selected.
paths=$(jq -r '
  if .tool_input.file_path then .tool_input.file_path
  else
    (.tool_input.command // "")
    | select(startswith("*** Begin Patch"))
    | split("\n")[]
    | select(test("^\\*\\*\\* (Add File|Update File|Move to): "))
    | sub("^\\*\\*\\* (Add File|Update File|Move to): "; "")
  end' <<< "$input")

cwd=$(jq -r '.cwd // empty' <<< "$input")

files=()
while IFS= read -r file; do
  [ -n "$file" ] || continue
  case "$file" in
    *.dart) ;;
    *) continue ;;
  esac
  # apply_patch paths may be relative to the session working directory.
  case "$file" in
    /*) ;;
    *) if [ -n "$cwd" ]; then file="$cwd/$file"; fi ;;
  esac
  if [ -f "$file" ]; then
    files+=("$file")
  fi
done <<< "$paths"

# Nothing Dart in this edit
if [ ${#files[@]} -eq 0 ]; then
  exit 0
fi

# Run dart analyze on the changed files
output=$(dart analyze "${files[@]}" 2>&1) || {
  echo "$output" >&2
  exit 2
}
