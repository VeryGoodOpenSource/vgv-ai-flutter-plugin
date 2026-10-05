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

# Label a case for the output. A command may be multi-line, which would wreck the
# aligned columns, so newlines are shown as a visible marker.
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

# The blocked commands appear literally below. Edit this file with Write/Edit, not a shell
# heredoc: the heredoc body is part of the command, and the hook under test would deny it.

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
echo "--- Quoted arguments are arguments, not commands (issue #147) ---"

# The regression that prompted the issue. A `|` inside a quoted regex is not a pipe,
# so an alternation listing the governed strings must not be chopped into subcommands.
# Both positions matter: the bug only fired when the match was NOT the last alternative,
# because then no closing quote attached to the token.
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

# Escapes and unbalanced quotes must not throw the scanner off.
assert_allowed "echo \\\"flutter test\\\""
assert_allowed "grep \"flutter test file.md"
assert_blocked "flutter test --name \"my app\""

# A quoted string may span newlines and is still one word.
assert_allowed "$(printf 'echo "hello\nflutter test\nworld"')"

echo ""
echo "--- Command position ---"

# Every unquoted separator opens a fresh command position. The quoted-alternation
# cases above prove a quoted `|` is inert; these prove an unquoted one still works.
assert_blocked "echo hi; flutter test"
assert_blocked "echo hi | flutter test"
assert_blocked "echo hi & flutter test"
assert_blocked "test -d lib || flutter test"

# A prefix does not stop something from being an invocation.
assert_blocked "ENV=1 flutter test"
assert_blocked "CI=true COVERAGE=1 dart test"
assert_blocked "(flutter test)"
assert_blocked "\$(flutter test)"
assert_blocked "\`flutter test\`"
assert_blocked "echo start && (very_good test)"

# Any wrapper passes through to the command it runs. There is no wrapper list: pass 2
# tests every adjacent token pair, so a wrapper this suite never names is covered too,
# whatever options it takes.
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

# melos is how a VGV monorepo runs anything across its packages, options and all.
assert_blocked "melos exec -- flutter test"
assert_blocked "melos exec --concurrency 1 -- dart test"

# Shell keywords and brace groups open a command position like any other separator.
assert_blocked "if true; then flutter test; fi"
assert_blocked "for f in a; do flutter test; done"
assert_blocked "{ flutter test; }"
assert_blocked "while :; do dart test; done"

# A path-qualified binary is the same command, so match on the basename.
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

# A path whose basename only resembles the command must not match.
assert_allowed "git add lib/router.dart test/router_test.dart"
assert_allowed "cp foo.dart test/"
assert_allowed "ls bin/flutter_tools"

# Comments are not modelled. A blocked command on a line after a comment is still
# caught, and an apostrophe in a comment does not swallow the following lines. The cost
# is that `; dart test` inside a comment is denied -- an accepted false positive, since
# a `#` comment inside a tool call is not something the agent writes.
assert_blocked "$(printf '# a comment\nflutter test')"
assert_blocked "$(printf 'ls # note\ncd pkg\nflutter test')"
assert_allowed "$(printf '# it%ss broken\nls -la' "'")"
assert_blocked "ls # fix; dart test"

# `$( )` and backticks execute inside double quotes, so a blocked command there is
# caught. Single quotes and a backslash-escaped `$` really are inert and stay allowed.
assert_blocked "OUT=\"\$(flutter test)\""
assert_blocked "echo \"\$(flutter test)\""
assert_blocked "echo \"\`flutter test\`\""
assert_blocked "if [ -z \"\$(dart test)\" ]; then echo x; fi"
assert_allowed "echo \"\\\$(flutter test)\""
assert_allowed "echo '\$(flutter test)'"
assert_allowed "echo \"\$(date) building\""
assert_allowed "VAR=\"\$(ls)\"; dart analyze"

# A quoted string handed to eval or sh -c is executed, so there the quotes are
# delimiters, not data.
assert_blocked "eval \"flutter test\""
assert_blocked "bash -c 'flutter test'"
assert_blocked "sh -c \"flutter test\""
assert_blocked "zsh -c \"cd pkg && dart test\""

echo ""
echo "--- Documented non-goals ---"
#
# These are allowed on purpose, and asserted so that changing one is a visible decision.
# A variable cannot be resolved without executing the command. The other three are forms
# nobody types; catching them would need a character-level shell lexer in place of the
# three substitutions, and the agent has never produced any of them.
assert_allowed "F=flutter; \$F test"
assert_allowed "\"flutter\" test"
assert_allowed "'dart' test"
assert_allowed "$(printf 'flutter \\\ntest --coverage')"

# A heredoc body is text, not a command position, but the scanner does not model
# heredocs and denies it. Pinned as the known limitation it is.
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

# The reason names what the hook actually matched, so a future misfire is self-
# explaining rather than describing an action the operator never attempted.
assert_reason_contains "Matched: flutter test" "deny reason quotes the matched command"

assert_blocked "fvm dart create my_app"
assert_reason_contains "Matched: dart create" "wrapper is skipped in the matched command"

# The very_good hits populate MATCHED through the same path; check one of them too.
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
