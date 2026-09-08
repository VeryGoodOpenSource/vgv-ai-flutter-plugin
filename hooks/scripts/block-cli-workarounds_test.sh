#!/bin/bash
# Tests for block-cli-workarounds.sh
#
# Usage: bash hooks/scripts/block-cli-workarounds_test.sh
#
# The hook reads a JSON payload from stdin containing tool_input.command,
# then exits 0 with a deny JSON on stdout if blocked, or exits 0 silently
# if allowed. We check stdout for the deny marker to determine the result.
#
# The same case list runs twice, once per harness. Claude Code fires the hook as
# "PreToolUse" against its Bash tool and reads
# hookSpecificOutput.permissionDecision; Gemini CLI fires it as "BeforeTool"
# against run_shell_command and reads a top-level decision field. Both tools
# carry the command under tool_input.command, so the verdict must be identical.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK="$SCRIPT_DIR/block-cli-workarounds.sh"

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

# Run hook with a command and check if it was blocked or allowed.
# Usage: run_hook "command string"
# Returns: "blocked" or "allowed"
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
}

echo "=== block-cli-workarounds tests: Claude Code (PreToolUse / Bash) ==="
HOOK_EVENT="PreToolUse"
run_cases

echo ""
echo "=== block-cli-workarounds tests: Gemini CLI (BeforeTool / run_shell_command) ==="
HOOK_EVENT="BeforeTool"
run_cases

echo ""
echo "--- Response shape per harness ---"
HOOK_EVENT="PreToolUse"
assert_deny_shape "dart test" \
  '.hookSpecificOutput.permissionDecision == "deny"' \
  "PreToolUse deny uses hookSpecificOutput.permissionDecision"
HOOK_EVENT="BeforeTool"
assert_deny_shape "dart test" \
  '.decision == "deny" and (.reason | length > 0)' \
  "BeforeTool deny uses top-level decision/reason"

# A payload with no hook_event_name (an older Claude Code build) must still get
# the Claude Code response shape rather than nothing at all.
echo ""
echo "--- Legacy payload without hook_event_name ---"
legacy_output=$(jq -n '{"tool_input":{"command":"dart test"}}' | bash "$HOOK" 2>/dev/null || true)
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
