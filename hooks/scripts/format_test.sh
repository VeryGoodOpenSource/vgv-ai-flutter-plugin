#!/bin/bash
# Tests for format.sh
#
# Usage: bash hooks/scripts/format_test.sh
#
# The hook reads a JSON payload from stdin and runs `dart format` on each Dart file the
# payload names, from tool_input.file_path (Claude Code) or tool_response (Codex's
# apply_patch). It never blocks. Every case runs against a stubbed dart on a PATH that
# contains nothing else and asserts on which files the stub was asked to format.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK="$SCRIPT_DIR/format.sh"

PASSED=0
FAILED=0

STUB_DIR="$(mktemp -d)"
trap 'rm -rf "$STUB_DIR"' EXIT

BASE_PATH="$(dirname "$(command -v jq)"):/usr/bin:/bin"

cat > "$STUB_DIR/dart" <<'STUB'
#!/bin/sh
echo "$*" >> "$(dirname "$0")/dart.log"
exit "$(cat "$(dirname "$0")/dart.exit" 2>/dev/null || echo 0)"
STUB
chmod +x "$STUB_DIR/dart"

dart_exits() { echo "$1" > "$STUB_DIR/dart.exit"; }

LAST_STATUS=0
LAST_CALLS=""
run_hook() {
  local payload="$1" path="${2:-$STUB_DIR:$BASE_PATH}"
  : > "$STUB_DIR/dart.log"
  LAST_STATUS=0
  printf '%s' "$payload" | env -i PATH="$path" bash "$HOOK" >/dev/null 2>&1 || LAST_STATUS=$?
  LAST_CALLS=$(cat "$STUB_DIR/dart.log")
}

pass() { printf "  \033[32mPASS\033[0m  %s\n" "$1"; PASSED=$((PASSED + 1)); }
fail() { printf "  \033[31mFAIL\033[0m  %s\n    %s\n" "$1" "$2"; FAILED=$((FAILED + 1)); }

assert_calls() {
  local label="$1" expected="$2"
  if [ "$LAST_CALLS" = "$expected" ]; then pass "$label"; else fail "$label" "dart was called with: $(printf '%s' "$LAST_CALLS" | tr '\n' '|')"; fi
}

assert_status() {
  local label="$1" expected="$2"
  if [ "$LAST_STATUS" -eq "$expected" ]; then pass "$label"; else fail "$label" "exit was $LAST_STATUS, expected $expected"; fi
}

codex_response() { printf 'Exit code: 0\nWall time: 0.1 seconds\nOutput:\nSuccess. Updated the following files:\n%s\n' "$1"; }

echo "=== format tests ==="

echo ""
echo "--- Claude Code ---"
run_hook "$(jq -n '{cwd:"/w", tool_name:"Edit", tool_input:{file_path:"/w/lib/a.dart"}, tool_response:{success:true}}')"
assert_calls  "formats the edited file"                          "format /w/lib/a.dart"
assert_status "exits 0"                                          0

run_hook "$(jq -n '{cwd:"/w", tool_input:{file_path:"/w/pubspec.yaml"}}')"
assert_calls  "skips a file that is not Dart"                    ""

echo ""
echo "--- Codex ---"
run_hook "$(jq -n --arg r "$(codex_response $'A lib/new.dart\nM lib/old.dart\nD lib/gone.dart')" '{cwd:"/w", tool_name:"apply_patch", tool_input:{command:"..."}, tool_response:$r}')"
assert_calls  "formats added and modified files, not deleted, relative to cwd" $'format /w/lib/new.dart\nformat /w/lib/old.dart'
assert_status "exits 0"                                          0

echo ""
echo "--- Never blocks ---"
dart_exits 1
run_hook "$(jq -n '{cwd:"/w", tool_input:{file_path:"/w/lib/a.dart"}}')"
assert_status "exits 0 even when dart format fails"              0
dart_exits 0

echo ""
echo "--- Without jq ---"
run_hook "$(jq -n '{tool_input:{file_path:"/w/lib/a.dart"}}')" "$STUB_DIR:/bin"
assert_calls  "runs nothing when jq is missing"                  ""
assert_status "exits 0 when jq is missing"                       0

echo ""
echo "=== Results: $PASSED passed, $FAILED failed ==="
[ "$FAILED" -eq 0 ] || exit 1
