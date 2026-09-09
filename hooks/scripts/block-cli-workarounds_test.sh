#!/bin/bash
# Tests for block-cli-workarounds.sh
#
# Usage: bash hooks/scripts/block-cli-workarounds_test.sh
#
# The hook reads a JSON payload from stdin containing tool_input.command,
# then exits 0 with a deny JSON on stdout if blocked, or exits 0 silently
# if allowed. We check stdout for the deny marker to determine the result.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK="$SCRIPT_DIR/block-cli-workarounds.sh"

PASSED=0
FAILED=0

# Run hook with a command and check if it was blocked or allowed.
# Usage: run_hook "command string"
# Returns: "blocked" or "allowed"
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

echo "=== block-cli-workarounds tests ==="
echo ""
echo "--- Should be BLOCKED ---"
assert_blocked "dart test"
assert_blocked "flutter test"
assert_blocked "dart test test/routing/foo_test.dart"
assert_blocked "flutter test --coverage"
assert_blocked "dart create my_app"
assert_blocked "flutter create my_app"
assert_blocked "very_good create flutter_app --project-name my_app"
assert_blocked "very_good test --coverage --min-coverage 100"
assert_blocked "very_good packages check licenses"
assert_blocked "cd /path && dart test"
assert_blocked "ENV=1 && flutter test --coverage"

echo ""
echo "--- Should be ALLOWED ---"
assert_allowed "dart analyze lib/foo.dart"
assert_allowed "dart format lib/foo.dart"
assert_allowed "dart pub get"
assert_allowed "dart fix --apply"
assert_allowed "flutter pub get"
assert_allowed "flutter analyze"
assert_allowed "git add lib/router.dart test/router_test.dart"
assert_allowed "dart analyze lib/foo.dart test/bar_test.dart"
assert_allowed "git commit -m 'fix dart test hook'"
assert_allowed "echo 'flutter create is blocked'"
assert_allowed "gh pr create --body 'use dart test instead'"
assert_allowed "git log --grep='dart test'"
assert_allowed "ls"
assert_allowed "pwd"

# Gemini CLI fires the same hook as "BeforeTool" against run_shell_command and
# reads a top-level decision/reason pair instead of hookSpecificOutput. Same
# verdict, different response shape.
echo ""
echo "--- Gemini CLI response shape ---"
gemini_out=$(jq -n '{"hook_event_name":"BeforeTool","tool_input":{"command":"dart test"}}' |
  bash "$HOOK" 2>/dev/null) || true
if echo "$gemini_out" | jq -e '.decision == "deny" and (.reason | length > 0)' >/dev/null 2>&1; then
  printf "  \033[32mPASS\033[0m  BeforeTool denies via top-level decision/reason\n"
  PASSED=$((PASSED + 1))
else
  printf "  \033[31mFAIL\033[0m  BeforeTool did not deny via top-level decision/reason\n"
  FAILED=$((FAILED + 1))
fi

echo ""
echo "=== Results: $PASSED passed, $FAILED failed ==="

if [ "$FAILED" -gt 0 ]; then
  exit 1
fi
