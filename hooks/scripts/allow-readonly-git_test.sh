#!/bin/bash
# Tests for allow-readonly-git.sh
#
# Usage: bash hooks/scripts/allow-readonly-git_test.sh
#
# The hook reads a JSON payload from stdin containing tool_input.command,
# then prints a deny JSON on stdout if denied, or exits silently if allowed.
# We check stdout for the deny marker to determine the result.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK="$SCRIPT_DIR/allow-readonly-git.sh"

PASSED=0
FAILED=0

run_hook() {
  local cmd="$1"
  local payload
  payload=$(jq -n --arg c "$cmd" '{"tool_input":{"command":$c}}')
  local output
  output=$(echo "$payload" | bash "$HOOK" 2>/dev/null) || true
  if echo "$output" | grep -q '"permissionDecision"'; then
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

echo "=== allow-readonly-git tests ==="
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

echo ""
echo "=== Results: $PASSED passed, $FAILED failed ==="

if [ "$FAILED" -gt 0 ]; then
  exit 1
fi
