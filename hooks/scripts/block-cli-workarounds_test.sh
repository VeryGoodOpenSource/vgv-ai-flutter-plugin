#!/bin/bash
# Tests for block-cli-workarounds.sh
#
# Usage: bash hooks/scripts/block-cli-workarounds_test.sh
#
# The hook reads a JSON payload from stdin. It exits 0 with a deny decision on stdout
# when the command is blocked, or exits 0 with no output when it stands aside. Every
# case reads the decision value itself, never just the presence of a decision, and
# treats a non-zero exit as its own outcome so a crashing hook cannot pass as
# "stood aside". Every case runs against a stubbed very_good on a PATH that contains
# nothing else, so results do not depend on what is installed on the machine.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK="$SCRIPT_DIR/block-cli-workarounds.sh"

PASSED=0
FAILED=0

STUB_DIR="$(mktemp -d)"
trap 'rm -rf "$STUB_DIR"' EXIT

BASE_PATH="$(dirname "$(command -v jq)"):/usr/bin:/bin:/usr/sbin:/sbin"

# Install a stubbed very_good. With a version argument the stub reports that version;
# with no argument it fails the way the real shim does when `dart` is missing from PATH.
# Usage: stub_cli [version]
stub_cli() {
  local version="${1:-}"
  local target="$STUB_DIR/very_good"
  if [ -z "$version" ]; then
    printf '#!/bin/sh\necho "very_good: dart: command not found" >&2\nexit 127\n' > "$target"
  else
    printf '#!/bin/sh\necho "very_good %s"\n' "$version" > "$target"
  fi
  chmod +x "$target"
}

no_cli() { rm -f "$STUB_DIR/very_good"; }

# Run the hook on a payload. Sets LAST_RESULT to the permissionDecision ("deny"/"allow"),
# "aside" when the hook exited 0 with no decision, or "exit:<status>" on a non-zero exit.
# The full stdout is left in LAST_OUTPUT for reason assertions. These are globals rather
# than printed values so that assertions do not have to call this in a subshell.
LAST_OUTPUT=""
LAST_RESULT=""
run_hook_payload() {
  local payload="$1"
  local status=0
  LAST_OUTPUT=$(printf '%s' "$payload" \
    | env -i PATH="$STUB_DIR:$BASE_PATH" HOME="$STUB_DIR" PUB_CACHE="$STUB_DIR/pub-cache" \
        bash "$HOOK" 2>/dev/null) || status=$?
  if [ "$status" -ne 0 ]; then
    LAST_RESULT="exit:$status"
  elif [ -z "$LAST_OUTPUT" ]; then
    LAST_RESULT="aside"
  else
    LAST_RESULT=$(echo "$LAST_OUTPUT" | jq -r '.hookSpecificOutput.permissionDecision // "malformed"')
  fi
}

# Run hook with a command as the shell tool (no tool_name, the way Claude Code's
# hooks.json matcher delivers it).
run_hook() {
  run_hook_payload "$(jq -n --arg c "$1" '{"tool_input":{"command":$c}}')"
}

# Show newlines as ~ so multi-line commands keep the columns aligned.
label_of() { printf '%s' "$1" | tr '\n' '~'; }

assert_blocked() {
  local cmd="$1"
  run_hook "$cmd"
  if [ "$LAST_RESULT" = "deny" ]; then
    printf "  \033[32mPASS\033[0m  blocked:  %s\n" "$(label_of "$cmd")"
    PASSED=$((PASSED + 1))
  else
    printf "  \033[31mFAIL\033[0m  expected deny but got %s:  %s\n" "$LAST_RESULT" "$(label_of "$cmd")"
    FAILED=$((FAILED + 1))
  fi
}

assert_allowed() {
  local cmd="$1"
  run_hook "$cmd"
  if [ "$LAST_RESULT" = "aside" ]; then
    printf "  \033[32mPASS\033[0m  allowed:  %s\n" "$(label_of "$cmd")"
    PASSED=$((PASSED + 1))
  else
    printf "  \033[31mFAIL\033[0m  expected aside but got %s:  %s\n" "$LAST_RESULT" "$(label_of "$cmd")"
    FAILED=$((FAILED + 1))
  fi
}

# Assert that the last hook output's permissionDecisionReason contains a string.
assert_reason_contains() {
  local needle="$1" label="$2"
  local reason
  reason=$(echo "$LAST_OUTPUT" | jq -r '.hookSpecificOutput.permissionDecisionReason // ""')
  if [[ "$reason" == *"$needle"* ]]; then
    printf "  \033[32mPASS\033[0m  reason mentions %-12s %s\n" "'$needle':" "$label"
    PASSED=$((PASSED + 1))
  else
    printf "  \033[31mFAIL\033[0m  reason lacks '%s':  %s\n    got: %s\n" "$needle" "$label" "$reason"
    FAILED=$((FAILED + 1))
  fi
}

# Edit with Write/Edit, not a heredoc: the hook reads the heredoc body and denies it.

echo "=== block-cli-workarounds tests ==="
stub_cli 1.5.0
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
assert_allowed ""
assert_allowed "   "

echo ""
echo "--- Quoted text is data (issue #147) ---"

# A quoted `|` is not a pipe. Both positions, since the bug only fired mid-alternation.
assert_allowed "grep -nE \"very_good|flutter test|foo\" CLAUDE.md"
assert_allowed "grep -nE \"very_good|flutter test\" CLAUDE.md"
assert_allowed "grep -nE \"flutter test|very_good|foo\" AGENTS.md"
assert_allowed "rg 'flutter create|dart create' docs/"

# A quoted phrase is a single word and runs nothing.
assert_allowed "echo \"flutter test\""
assert_allowed "echo 'flutter test'"
assert_allowed "git commit -m \"ban flutter test | dart test\""

# One quote type is inert inside the other.
assert_allowed "echo 'say \"flutter test\" now'"
assert_allowed "echo \"say 'flutter test' now\""

# Escapes and unbalanced quotes.
assert_allowed "echo \\\"flutter test\\\""
assert_allowed "grep \"flutter test file.md"
assert_blocked "flutter test --name \"my app\""

# A quoted string may span newlines and is still one word.
assert_allowed "$(printf 'echo "hello\nflutter test\nworld"')"

echo ""
echo "--- Command position ---"

# Unquoted separators open a command position.
assert_blocked "echo hi; flutter test"
assert_blocked "echo hi | flutter test"
assert_blocked "echo hi & flutter test"
assert_blocked "test -d lib || flutter test"

# A prefix is still an invocation.
assert_blocked "ENV=1 flutter test"
assert_blocked "CI=true COVERAGE=1 dart test"
assert_blocked "(flutter test)"
assert_blocked "\$(flutter test)"
assert_blocked "\`flutter test\`"
assert_blocked "echo start && (very_good test)"

# Wrappers need no list: every adjacent word pair is checked.
assert_blocked "fvm flutter test"
assert_blocked "command flutter test"
assert_blocked "env flutter test"
assert_blocked "env FOO=1 flutter test"
assert_blocked "env -i flutter test"
assert_blocked "sudo flutter test"
assert_blocked "sudo -u ci flutter test"
assert_blocked "nohup flutter test"
assert_blocked "exec flutter test"
assert_blocked "time flutter test"
assert_blocked "timeout 60 flutter test"
assert_blocked "nice -n 10 flutter test"
assert_blocked "xargs flutter test"

# melos runs commands across a VGV monorepo.
assert_blocked "melos exec -- flutter test"
assert_blocked "melos exec --concurrency 1 -- dart test"

# Shell keywords and brace groups are separators.
assert_blocked "if true; then flutter test; fi"
assert_blocked "for f in a; do flutter test; done"
assert_blocked "{ flutter test; }"
assert_blocked "while :; do dart test; done"

# Match on the basename.
assert_blocked "/usr/local/bin/flutter test"
assert_blocked "./flutter test"
assert_blocked "\$FLUTTER_ROOT/bin/flutter test"
assert_blocked "../sdk/bin/dart test"

# ...but only when the wrapped command is itself blocked.
assert_allowed "fvm flutter pub get"
assert_allowed "command -v flutter"
assert_allowed "env | grep PATH"
assert_allowed "melos exec -- dart analyze"
assert_allowed "timeout 60 dart pub get"
assert_allowed "/usr/local/bin/flutter analyze"

# A wrapper with nothing after it has no pair to match.
assert_allowed "fvm"
assert_allowed "env -i"
assert_allowed "ENV=1"

# A basename that only resembles the command.
assert_allowed "git add lib/router.dart test/router_test.dart"
assert_allowed "cp foo.dart test/"
assert_allowed "ls bin/flutter_tools"

# Comments are not modelled. `; dart test` inside one is denied: accepted, since the
# agent does not write comments in tool calls.
assert_blocked "$(printf '# a comment\nflutter test')"
assert_blocked "$(printf 'ls # note\ncd pkg\nflutter test')"
assert_allowed "$(printf '# it%ss broken\nls -la' "'")"
assert_blocked "ls # fix; dart test"

# `$( )` and backticks run inside double quotes. Single quotes and `\$` are inert.
assert_blocked "OUT=\"\$(flutter test)\""
assert_blocked "echo \"\$(flutter test)\""
assert_blocked "echo \"\`flutter test\`\""
assert_blocked "if [ -z \"\$(dart test)\" ]; then echo x; fi"
assert_allowed "echo \"\\\$(flutter test)\""
assert_allowed "echo '\$(flutter test)'"
assert_allowed "echo \"\$(date) building\""
assert_allowed "VAR=\"\$(ls)\"; dart analyze"

# eval and sh -c run their string.
assert_blocked "eval \"flutter test\""
assert_blocked "bash -c 'flutter test'"
assert_blocked "sh -c \"flutter test\""
assert_blocked "zsh -c \"cd pkg && dart test\""

echo ""
echo "--- Documented non-goals ---"
#
# Allowed on purpose and pinned. A variable needs execution to resolve; the rest are
# forms nobody types.
assert_allowed "F=flutter; \$F test"
assert_allowed "\"flutter\" test"
assert_allowed "'dart' test"
assert_allowed "$(printf 'flutter \\\ntest --coverage')"

# Heredoc bodies are not modelled; denied as a known limitation.
assert_blocked "$(printf 'cat <<EOF\nflutter test\nEOF')"

echo ""
echo "--- Tool scoping ---"

# Run hook with an explicit tool_name alongside the command.
run_hook_for_tool() {
  run_hook_payload "$(jq -n --arg t "$1" --arg c "$2" '{"tool_name":$t,"tool_input":{"command":$c}}')"
}

# Usage: assert_tool_result deny|aside <tool_name> <command>
assert_tool_result() {
  local expected="$1"
  local tool="$2"
  local cmd="$3"
  run_hook_for_tool "$tool" "$cmd"
  if [ "$LAST_RESULT" = "$expected" ]; then
    printf "  \033[32mPASS\033[0m  %-8s %-22s %s\n" "$expected" "$tool" "$cmd"
    PASSED=$((PASSED + 1))
  else
    printf "  \033[31mFAIL\033[0m  expected %s but got %s:  %s / %s\n" "$expected" "$LAST_RESULT" "$tool" "$cmd"
    FAILED=$((FAILED + 1))
  fi
}

# The host's shell tool is this hook's business, whatever it is named.
assert_tool_result deny  "Bash"  "flutter test"
assert_tool_result deny  "Shell" "flutter test"
assert_tool_result deny  "Bash"  "very_good create flutter_app"

# Anything else is not. An unrelated MCP tool can carry a `command` argument of its own,
# and reaches this hook on any host that does not apply the hooks.json matcher.
assert_tool_result aside "MCP:run_terminal_cmd" "flutter test"
assert_tool_result aside "MCP:browser_tabs"     "flutter test"
assert_tool_result aside "mcp__some-server__exec" "dart test --coverage"
assert_tool_result aside "Write"                "flutter test"

echo ""
echo "--- Deny reason follows the CLI status ---"

stub_cli 1.5.0
assert_blocked "flutter test"
assert_reason_contains "MCP 'test' tool" "current CLI redirects to the MCP tool"

# The reason names the match.
assert_reason_contains "Matched: flutter test" "deny reason quotes the matched command"

assert_blocked "fvm dart create my_app"
assert_reason_contains "Matched: dart create" "wrapper is skipped in the matched command"

# very_good hits name the match too.
assert_blocked "very_good packages check licenses"
assert_reason_contains "Matched: very_good packages" "very_good hits name the matched command"

stub_cli 1.2.9
assert_blocked "flutter test"
assert_reason_contains "too old" "outdated CLI asks for an update"

no_cli
assert_blocked "flutter test"
assert_reason_contains "not found" "missing CLI asks for an install"

# The MCP server starts through the same very_good shim, so redirecting to it when the
# shim cannot exec dart would be a dead end. The reason must point at PATH instead.
stub_cli
assert_blocked "flutter test"
assert_reason_contains "dart is not on the PATH" "CLI that cannot run points at PATH, not the MCP tool"

echo ""
echo "--- Deny reason says the whole call was refused ---"

# A command chained with the blocked one is refused with it. Every reason must say so,
# or the agent assumes the chained command's side effect happened.
stub_cli 1.5.0
assert_blocked "python3 edit_pubspec.py && dart test"
assert_reason_contains "none of it ran" "chained command, current CLI"

stub_cli 1.2.9
assert_blocked "python3 edit_pubspec.py && dart test"
assert_reason_contains "none of it ran" "chained command, outdated CLI"

no_cli
assert_blocked "python3 edit_pubspec.py && dart test"
assert_reason_contains "none of it ran" "chained command, missing CLI"

stub_cli
assert_blocked "python3 edit_pubspec.py && dart test"
assert_reason_contains "none of it ran" "chained command, CLI that cannot run"

echo ""
echo "=== Results: $PASSED passed, $FAILED failed ==="

if [ "$FAILED" -gt 0 ]; then
  exit 1
fi
