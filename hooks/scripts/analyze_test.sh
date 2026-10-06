#!/bin/bash
# Tests for analyze.sh
#
# Usage: bash hooks/scripts/analyze_test.sh
#
# The hook reads a JSON payload from stdin and runs `dart analyze` on each Dart file the
# payload names. Claude Code names one in tool_input.file_path; Codex's apply_patch names
# each in tool_response as "A path" / "M path", relative to cwd. Every case runs against a
# stubbed dart on a PATH that contains nothing else, and asserts on exactly which files the
# stub was asked to analyze, so results do not depend on a Dart SDK being installed.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK="$SCRIPT_DIR/analyze.sh"

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

# A PATH with cat, the one coreutil the hook uses before its jq check, and nothing else.
# Built from a symlink rather than named as /bin, because on a merged-/usr Linux /bin is
# /usr/bin and so still has jq on it.
NOJQ_DIR="$STUB_DIR/nojq"
mkdir -p "$NOJQ_DIR" && ln -s "$(command -v cat)" "$NOJQ_DIR/cat"
NOJQ_PATH="$STUB_DIR:$NOJQ_DIR"

# Run the hook on a payload. Leaves the exit status in LAST_STATUS, stderr in LAST_STDERR,
# and every `dart` invocation (one per line, e.g. "analyze /w/lib/a.dart") in LAST_CALLS.
LAST_STATUS=0
LAST_STDERR=""
LAST_CALLS=""
run_hook() {
  local payload="$1" path="${2:-$STUB_DIR:$BASE_PATH}"
  : > "$STUB_DIR/dart.log"
  LAST_STATUS=0
  LAST_STDERR=$(printf '%s' "$payload" | env -i PATH="$path" bash "$HOOK" 2>&1 >/dev/null) || LAST_STATUS=$?
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

# The real response text Codex sends for an apply_patch, captured from codex-cli 0.153.4.
codex_response() { printf 'Exit code: 0\nWall time: 0.1 seconds\nOutput:\nSuccess. Updated the following files:\n%s\n' "$1"; }

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
echo "--- Codex: files named in tool_response ---"
run_hook "$(jq -n --arg r "$(codex_response 'M /abs/lib/x.dart')" '{cwd:"/w", tool_name:"apply_patch", tool_input:{command:"*** Begin Patch\n*** Update File: /abs/lib/x.dart\n*** End Patch"}, tool_response:$r}')"
assert_calls  "analyzes an absolute path as given"              "analyze /abs/lib/x.dart"

run_hook "$(jq -n --arg r "$(codex_response 'A lib/new.dart')" '{cwd:"/w", tool_name:"apply_patch", tool_input:{command:"..."}, tool_response:$r}')"
assert_calls  "resolves a relative path against the payload cwd" "analyze /w/lib/new.dart"

run_hook "$(jq -n --arg r "$(codex_response $'A lib/new.dart\nM lib/old.dart\nD lib/gone.dart\nM lib/renamed.dart')" '{cwd:"/w", tool_name:"apply_patch", tool_input:{command:"..."}, tool_response:$r}')"
assert_calls  "analyzes added, modified and renamed files, not deleted" $'analyze /w/lib/new.dart\nanalyze /w/lib/old.dart\nanalyze /w/lib/renamed.dart'

run_hook "$(jq -n --arg r "$(codex_response $'M lib/a.dart\nM lib/b.md')" '{cwd:"/w", tool_name:"apply_patch", tool_input:{command:"..."}, tool_response:$r}')"
assert_calls  "skips a non-Dart file in a patch"                 "analyze /w/lib/a.dart"

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

run_hook "$(jq -n --arg r "$(codex_response $'M lib/a.dart\nM lib/b.dart')" '{cwd:"/w", tool_input:{command:"..."}, tool_response:$r}')"
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
