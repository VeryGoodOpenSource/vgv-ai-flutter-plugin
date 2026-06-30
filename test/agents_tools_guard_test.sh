#!/bin/bash
# Tests for agents_tools_guard.sh
#
# Usage: bash test/agents_tools_guard_test.sh
#
# Drives the guard against synthetic agents/ directories (via the AGENTS_DIR
# override) and asserts it exits 0 on clean input and 1 on a violation, for
# both the inline and YAML block-list `tools:` forms.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GUARD="$SCRIPT_DIR/agents_tools_guard.sh"

PASSED=0
FAILED=0

WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

# Write a single agent file into a fresh agents dir and run the guard against it.
# Usage: run_guard <agent-file-contents>
# Echoes the guard's exit code.
run_guard() {
  local contents="$1"
  local dir="$WORKDIR/agents"
  rm -rf "$dir"
  mkdir -p "$dir"
  printf '%s\n' "$contents" > "$dir/sample.md"
  AGENTS_DIR="$dir" bash "$GUARD" >/dev/null 2>&1
  echo "$?"
}

assert_exit() {
  local label="$1" expected="$2" actual="$3"
  if [ "$actual" = "$expected" ]; then
    printf "  \033[32mPASS\033[0m  %s (exit %s)\n" "$label" "$actual"
    PASSED=$((PASSED + 1))
  else
    printf "  \033[31mFAIL\033[0m  %s: expected exit %s, got %s\n" "$label" "$expected" "$actual"
    FAILED=$((FAILED + 1))
  fi
}

echo "=== agents_tools_guard tests ==="
echo ""

# Clean: inline read-only tools, Bash paired with the hook.
clean_inline='---
name: sample
tools: Read, Glob, Grep, Bash, mcp__dart__analyze_files
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "bash ${CLAUDE_PLUGIN_ROOT}/hooks/scripts/allow-readonly-git.sh"
---
body'
assert_exit "clean inline tools + Bash hook" 0 "$(run_guard "$clean_inline")"

# Violation: inline form with a write tool.
bad_inline='---
name: sample
tools: Read, Write, Glob
---
body'
assert_exit "inline form with Write" 1 "$(run_guard "$bad_inline")"

# Violation: YAML block-list form with a write tool (the false-negative class).
bad_list='---
name: sample
tools:
  - Read
  - Edit
  - Glob
---
body'
assert_exit "block-list form with Edit" 1 "$(run_guard "$bad_list")"

# Clean: YAML block-list form, all read-only, no Bash.
clean_list='---
name: sample
tools:
  - Read
  - Glob
  - Grep
---
body'
assert_exit "block-list form read-only" 0 "$(run_guard "$clean_list")"

# Violation: Bash granted but no read-only git hook referenced.
bash_no_hook='---
name: sample
tools: Read, Bash
---
body'
assert_exit "Bash without hook" 1 "$(run_guard "$bash_no_hook")"

# Violation: NotebookEdit in block-list form.
bad_notebook='---
name: sample
tools:
  - Read
  - NotebookEdit
---
body'
assert_exit "block-list form with NotebookEdit" 1 "$(run_guard "$bad_notebook")"

echo ""
echo "=== Results: $PASSED passed, $FAILED failed ==="

if [ "$FAILED" -gt 0 ]; then
  exit 1
fi
