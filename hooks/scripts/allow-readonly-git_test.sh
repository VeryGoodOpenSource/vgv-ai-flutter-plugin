#!/bin/bash
# Tests for allow-readonly-git.sh
#
# Usage: bash hooks/scripts/allow-readonly-git_test.sh
#
# The hook reads a JSON payload from stdin containing tool_input.command,
# then prints a deny JSON on stdout if denied, or exits silently if allowed.
# We check stdout for the deny marker to determine the result.
#
# The same case list runs twice, once per harness. Claude Code fires the hook as
# "PreToolUse" and reads hookSpecificOutput.permissionDecision; Gemini CLI fires
# the same hook as "BeforeTool" and reads a top-level decision field. The verdict
# must be identical either way.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK="$SCRIPT_DIR/allow-readonly-git.sh"

PASSED=0
FAILED=0

# Event name for the harness currently under test.
HOOK_EVENT="PreToolUse"

hook_output() {
  local cmd="$1"
  local payload
  payload=$(jq -n --arg c "$cmd" --arg e "$HOOK_EVENT" \
    '{"hook_event_name":$e,"tool_input":{"command":$c}}')
  echo "$payload" | bash "$HOOK" 2>/dev/null || true
}

run_hook() {
  local output
  output=$(hook_output "$1")
  if echo "$output" |
    jq -e '.hookSpecificOutput.permissionDecision == "deny" or .decision == "deny"' \
      >/dev/null 2>&1; then
    echo "blocked"
  else
    echo "allowed"
  fi
}

assert_blocked() {
  local cmd="$1"
  local result
  result=$(run_hook "$cmd")
  if [ "$result" = "blocked" ]; then
    printf "  \033[32mPASS\033[0m  blocked:  %s\n" "$cmd"
    PASSED=$((PASSED + 1))
  else
    printf "  \033[31mFAIL\033[0m  expected blocked but allowed:  %s\n" "$cmd"
    FAILED=$((FAILED + 1))
  fi
}

assert_allowed() {
  local cmd="$1"
  local result
  result=$(run_hook "$cmd")
  if [ "$result" = "allowed" ]; then
    printf "  \033[32mPASS\033[0m  allowed:  %s\n" "$cmd"
    PASSED=$((PASSED + 1))
  else
    printf "  \033[31mFAIL\033[0m  expected allowed but blocked:  %s\n" "$cmd"
    FAILED=$((FAILED + 1))
  fi
}

# Assert the deny payload uses the response shape the given harness reads.
assert_deny_shape() {
  local cmd="$1"
  local filter="$2"
  local label="$3"
  local output
  output=$(hook_output "$cmd")
  if echo "$output" | jq -e "$filter" >/dev/null 2>&1; then
    printf "  \033[32mPASS\033[0m  %s\n" "$label"
    PASSED=$((PASSED + 1))
  else
    printf "  \033[31mFAIL\033[0m  %s (got: %s)\n" "$label" "$(echo "$output" | tr -d '\n')"
    FAILED=$((FAILED + 1))
  fi
}

run_cases() {
  echo ""
  echo "--- Should be ALLOWED ---"
  assert_allowed "git diff"
  assert_allowed "git status"
  assert_allowed "git status -s"
  assert_allowed "git diff --stat"
  assert_allowed "git diff main...HEAD"
  assert_allowed "  git diff HEAD~1"

  echo ""
  echo "--- Should be BLOCKED ---"
  assert_blocked "git checkout ."
  assert_blocked "git apply patch.diff"
  assert_blocked "git commit -m wip"
  assert_blocked "git diff > out.txt"
  assert_blocked "git status; rm -rf x"
  assert_blocked "git diff && rm x"
  assert_blocked "git diff | tee out.txt"
  assert_blocked 'git diff $(rm x)'
  assert_blocked "rm -rf /"
  assert_blocked "sed -i s/a/b/ file"
  assert_blocked "echo hi > file"
  assert_blocked "diff a b"
}

echo "=== allow-readonly-git tests: Claude Code (PreToolUse) ==="
HOOK_EVENT="PreToolUse"
run_cases

echo ""
echo "=== allow-readonly-git tests: Gemini CLI (BeforeTool) ==="
HOOK_EVENT="BeforeTool"
run_cases

echo ""
echo "--- Response shape per harness ---"
HOOK_EVENT="PreToolUse"
assert_deny_shape "rm -rf /" \
  '.hookSpecificOutput.permissionDecision == "deny"' \
  "PreToolUse deny uses hookSpecificOutput.permissionDecision"
HOOK_EVENT="BeforeTool"
assert_deny_shape "rm -rf /" \
  '.decision == "deny" and (.reason | length > 0)' \
  "BeforeTool deny uses top-level decision/reason"

# A payload with no hook_event_name (an older Claude Code build) must still get
# the Claude Code response shape rather than nothing at all.
echo ""
echo "--- Legacy payload without hook_event_name ---"
legacy_output=$(jq -n '{"tool_input":{"command":"rm -rf /"}}' | bash "$HOOK" 2>/dev/null || true)
if echo "$legacy_output" | jq -e '.hookSpecificOutput.permissionDecision == "deny"' >/dev/null 2>&1; then
  printf "  \033[32mPASS\033[0m  defaults to the Claude Code deny shape\n"
  PASSED=$((PASSED + 1))
else
  printf "  \033[31mFAIL\033[0m  expected the Claude Code deny shape\n"
  FAILED=$((FAILED + 1))
fi

echo ""
echo "=== Results: $PASSED passed, $FAILED failed ==="

if [ "$FAILED" -gt 0 ]; then
  exit 1
fi
