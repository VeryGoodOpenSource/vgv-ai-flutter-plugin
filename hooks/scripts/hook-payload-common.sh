#!/bin/bash
# Shared helpers for reading a hook payload that may come from either harness.
#
# Claude Code and Codex describe the same edit differently:
#
#   Claude Code  Edit / Write  ->  .tool_input.file_path  (one path)
#   Codex        apply_patch   ->  .tool_input.command    (an apply_patch envelope)
#
# changed_dart_files() normalizes both into a newline-separated list of existing
# `.dart` paths, so analyze.sh and format.sh stay single-sourced across harnesses.
#
# Every branch is written with `if` rather than `&&` so that sourcing this file
# from a script running under `set -e` cannot abort on a false test.

# Print the paths an apply_patch envelope creates or updates, one per line.
#
# $1 = the raw envelope.
#
# Grammar (from the Codex apply_patch parser):
#   begin_patch:  "*** Begin Patch" LF
#   add_hunk:     "*** Add File: " filename LF add_line+
#   delete_hunk:  "*** Delete File: " filename LF
#   update_hunk:  "*** Update File: " filename LF change_move? change?
#   change_move:  "*** Move to: " filename LF
#
# Deleted files are skipped — there is nothing left to analyze or format. For a
# renamed file the `Move to:` destination wins, because that is the path on disk
# once the patch lands.
apply_patch_paths() {
  printf '%s\n' "$1" | awk '
    function flush() { if (path != "") { print path; path = "" } }
    /^\*\*\* (Add|Update) File: / { flush(); path = substr($0, index($0, ": ") + 2); next }
    /^\*\*\* Move to: /           { path = substr($0, index($0, ": ") + 2); next }
    /^\*\*\* Delete File: /       { flush(); next }
    /^\*\*\* End Patch/           { flush(); next }
    END                           { flush() }
  '
}

# Print the `.dart` files a hook payload touched, one per line.
#
# $1 = the raw hook payload JSON. Only files that exist on disk are printed, so a
# deleted or moved-away path never reaches `dart analyze`.
changed_dart_files() {
  local input="$1"
  local file_path command cwd path

  # Claude Code: a single explicit path.
  file_path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty')
  if [ -n "$file_path" ]; then
    case "$file_path" in
      *.dart)
        if [ -f "$file_path" ]; then
          printf '%s\n' "$file_path"
        fi
        ;;
    esac
    return 0
  fi

  # Codex: an apply_patch envelope in `command`.
  command=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')
  case "$command" in
    '*** Begin Patch'*) ;;
    *) return 0 ;;
  esac

  cwd=$(printf '%s' "$input" | jq -r '.cwd // empty')
  while IFS= read -r path; do
    if [ -z "$path" ]; then
      continue
    fi
    case "$path" in
      *.dart) ;;
      *) continue ;;
    esac
    # apply_patch paths may be relative to the session working directory.
    case "$path" in
      /*) ;;
      *)
        if [ -n "$cwd" ]; then
          path="$cwd/$path"
        fi
        ;;
    esac
    if [ -f "$path" ]; then
      printf '%s\n' "$path"
    fi
  done < <(apply_patch_paths "$command")

  return 0
}
