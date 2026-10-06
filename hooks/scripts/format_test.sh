#!/bin/bash
# Tests for format.sh
#
# Usage: bash hooks/scripts/format_test.sh
#
# The hook runs `dart format` on each Dart file it is given: the paths passed as
# arguments, or tool_input.file_path from the JSON payload on stdin when there are none.
# It never blocks. Every case runs against a stubbed dart on a PATH that contains nothing
# else and asserts on which files the stub was asked to format.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK="$SCRIPT_DIR/format.sh"

# Invoked by absolute path: `env -i PATH=...` resolves the command it runs with the PATH
# it was just given, and the no-jq PATH below deliberately holds almost nothing.
BASH_BIN="$(command -v bash)"

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

# A PATH with the coreutils the hook needs besides jq, and nothing else. Built from
# symlinks rather than named as /bin, because on a merged-/usr Linux /bin is /usr/bin and
# so still has jq on it.
NOJQ_DIR="$STUB_DIR/nojq"
mkdir -p "$NOJQ_DIR"
for tool in cat dirname; do ln -s "$(command -v "$tool")" "$NOJQ_DIR/$tool"; done
NOJQ_PATH="$STUB_DIR:$NOJQ_DIR"

LAST_STATUS=0
LAST_CALLS=""
run_hook() {
  local payload="$1" path="${2:-$STUB_DIR:$BASE_PATH}"
  shift; [ "$#" -eq 0 ] || shift
  : > "$STUB_DIR/dart.log"
  LAST_STATUS=0
  printf '%s' "$payload" | env -i PATH="$path" "$BASH_BIN" "$HOOK" "$@" >/dev/null 2>&1 || LAST_STATUS=$?
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


echo "=== format tests ==="

echo ""
echo "--- Claude Code ---"
run_hook "$(jq -n '{cwd:"/w", tool_name:"Edit", tool_input:{file_path:"/w/lib/a.dart"}, tool_response:{success:true}}')"
assert_calls  "formats the edited file"                          "format /w/lib/a.dart"
assert_status "exits 0"                                          0

run_hook "$(jq -n '{cwd:"/w", tool_input:{file_path:"/w/pubspec.yaml"}}')"
assert_calls  "skips a file that is not Dart"                    ""

echo ""
echo "--- Files passed as arguments ---"
run_hook '{}' "" /w/lib/new.dart /w/lib/old.dart /w/lib/notes.md
assert_calls  "formats every Dart argument"                      $'format /w/lib/new.dart\nformat /w/lib/old.dart'
assert_status "exits 0"                                          0

run_hook '{}' "$NOJQ_PATH" /w/lib/a.dart
assert_calls  "needs no jq when given arguments"                 "format /w/lib/a.dart"

echo ""
echo "--- Never blocks ---"
dart_exits 1
run_hook "$(jq -n '{cwd:"/w", tool_input:{file_path:"/w/lib/a.dart"}}')"
assert_status "exits 0 even when dart format fails"              0
dart_exits 0

echo ""
echo "--- Without jq ---"
run_hook "$(jq -n '{tool_input:{file_path:"/w/lib/a.dart"}}')" "$NOJQ_PATH"
assert_calls  "runs nothing when jq is missing"                  ""
assert_status "exits 0 when jq is missing"                       0

echo ""
echo "=== Results: $PASSED passed, $FAILED failed ==="
[ "$FAILED" -eq 0 ] || exit 1
