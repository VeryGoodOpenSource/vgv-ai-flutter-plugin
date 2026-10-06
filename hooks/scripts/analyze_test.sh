#!/bin/bash
# Tests for analyze.sh
#
# Usage: bash hooks/scripts/analyze_test.sh
#
# The hook runs `dart analyze` on each Dart file it is given: the paths passed as
# arguments, or tool_input.file_path from the JSON payload on stdin when there are none.
# Every case runs against a stubbed dart on a PATH that contains nothing else, and asserts
# on exactly which files the stub was asked to analyze, so results do not depend on a Dart
# SDK being installed.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK="$SCRIPT_DIR/analyze.sh"

# Invoked by absolute path: `env -i PATH=...` resolves the command it runs with the PATH
# it was just given, and the no-jq PATH below deliberately holds almost nothing.
BASH_BIN="$(command -v bash)"

PASSED=0
FAILED=0

STUB_DIR="$(mktemp -d)"
trap 'rm -rf "$STUB_DIR"' EXIT

BASE_PATH="$(dirname "$(command -v jq)"):/usr/bin:/bin"

# A stubbed dart that logs its arguments, one call per line, and exits with the status in
# dart.exit (default 0). On a non-zero exit it prints an issue the way `dart analyze` does.
cat > "$STUB_DIR/dart" <<'STUB'
#!/bin/sh
echo "$*" >> "$(dirname "$0")/dart.log"
status=$(cat "$(dirname "$0")/dart.exit" 2>/dev/null || echo 0)
[ "$status" -ne 0 ] && echo "  error - lib/a.dart:1:1 - Undefined name 'x'. - undefined_identifier"
exit "$status"
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

# Run the hook on a payload, with any hook arguments after the PATH. Leaves the exit status in LAST_STATUS, stderr in LAST_STDERR,
# and every `dart` invocation (one per line, e.g. "analyze /w/lib/a.dart") in LAST_CALLS.
LAST_STATUS=0
LAST_STDERR=""
LAST_CALLS=""
run_hook() {
  local payload="$1" path="${2:-$STUB_DIR:$BASE_PATH}"
  shift; [ "$#" -eq 0 ] || shift
  : > "$STUB_DIR/dart.log"
  LAST_STATUS=0
  LAST_STDERR=$(printf '%s' "$payload" | env -i PATH="$path" "$BASH_BIN" "$HOOK" "$@" 2>&1 >/dev/null) || LAST_STATUS=$?
  LAST_CALLS=$(cat "$STUB_DIR/dart.log")
}

pass() { printf "  \033[32mPASS\033[0m  %s\n" "$1"; PASSED=$((PASSED + 1)); }
fail() { printf "  \033[31mFAIL\033[0m  %s\n    %s\n" "$1" "$2"; FAILED=$((FAILED + 1)); }

# Usage: assert_calls <label> <expected calls, newline separated>
assert_calls() {
  local label="$1" expected="$2"
  if [ "$LAST_CALLS" = "$expected" ]; then pass "$label"; else fail "$label" "dart was called with: $(printf '%s' "$LAST_CALLS" | tr '\n' '|')"; fi
}

# Usage: assert_status <label> <expected exit>
assert_status() {
  local label="$1" expected="$2"
  if [ "$LAST_STATUS" -eq "$expected" ]; then pass "$label"; else fail "$label" "exit was $LAST_STATUS, expected $expected"; fi
}


echo "=== analyze tests ==="

echo ""
echo "--- Claude Code: one file in tool_input.file_path ---"
run_hook "$(jq -n '{cwd:"/w", tool_name:"Edit", tool_input:{file_path:"/w/lib/a.dart", old_string:"x", new_string:"y"}, tool_response:{filePath:"/w/lib/a.dart", success:true}}')"
assert_calls  "analyzes the edited file"                         "analyze /w/lib/a.dart"
assert_status "exits 0 when analysis passes"                     0

run_hook "$(jq -n '{cwd:"/w", tool_name:"Write", tool_input:{file_path:"/w/README.md", content:"# hi"}, tool_response:{success:true}}')"
assert_calls  "skips a file that is not Dart"                    ""
assert_status "exits 0 for a non-Dart file"                      0

echo ""
echo "--- Files passed as arguments ---"
run_hook '{}' "" /abs/lib/x.dart
assert_calls  "analyzes a file given as an argument"             "analyze /abs/lib/x.dart"

run_hook "$(jq -n '{tool_input:{file_path:"/w/lib/payload.dart"}}')" "" /w/lib/arg.dart
assert_calls  "prefers the arguments over the payload"           "analyze /w/lib/arg.dart"

run_hook '{}' "" /w/lib/a.dart /w/lib/b.dart "/w/lib/with space.dart"
assert_calls  "analyzes every argument"                          $'analyze /w/lib/a.dart\nanalyze /w/lib/b.dart\nanalyze /w/lib/with space.dart'

run_hook '{}' "" /w/lib/a.dart /w/README.md
assert_calls  "skips a non-Dart argument"                        "analyze /w/lib/a.dart"

run_hook '{}' "$NOJQ_PATH" /w/lib/a.dart
assert_calls  "needs no jq when given arguments"                 "analyze /w/lib/a.dart"

echo ""
echo "--- Payloads that name no file ---"
run_hook "$(jq -n '{cwd:"/w", tool_name:"Bash", tool_input:{command:"ls"}, tool_response:"Exit code: 0\nOutput:\nlib\n"}')"
assert_calls  "runs nothing for a shell call"                    ""
assert_status "exits 0 for a shell call"                         0

echo ""
echo "--- Failures block ---"
dart_exits 1
run_hook "$(jq -n '{cwd:"/w", tool_input:{file_path:"/w/lib/a.dart"}}')"
assert_status "exits 2 when analysis fails"                      2
if [[ "$LAST_STDERR" == *"undefined_identifier"* ]]; then pass "forwards the analyzer output on stderr"; else fail "forwards the analyzer output on stderr" "stderr was: $LAST_STDERR"; fi

run_hook '{}' "" /w/lib/a.dart /w/lib/b.dart
assert_calls  "still analyzes every file after one fails"        $'analyze /w/lib/a.dart\nanalyze /w/lib/b.dart'
assert_status "exits 2 when any file fails"                      2
dart_exits 0

echo ""
echo "--- Without jq ---"
run_hook "$(jq -n '{tool_input:{file_path:"/w/lib/a.dart"}}')" "$NOJQ_PATH"
assert_calls  "runs nothing when jq is missing"                  ""
assert_status "exits 0 when jq is missing"                       0
if [[ "$LAST_STDERR" == *"jq not found, skipping"* ]]; then pass "says why it skipped"; else fail "says why it skipped" "stderr was: $LAST_STDERR"; fi

echo ""
echo "=== Results: $PASSED passed, $FAILED failed ==="
[ "$FAILED" -eq 0 ] || exit 1
