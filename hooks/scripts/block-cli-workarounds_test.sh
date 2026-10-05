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

# The hook's own trigger strings, assembled at runtime. Writing them literally would
# make this file's own edits and greps trip the hook it tests -- which is the exact
# bug issue #147 reports.
FL="fl""utter"
TE="te""st"
VG="very_""good"
CR="cre""ate"

echo "=== block-cli-workarounds tests ==="
stub_cli 1.5.0
echo ""
echo "--- Should be BLOCKED ---"
assert_blocked "dart $TE"
assert_blocked "$FL $TE"
assert_blocked "dart $TE test/routing/foo_test.dart"
assert_blocked "$FL $TE --coverage"
assert_blocked "dart $CR my_app"
assert_blocked "$FL create my_app"
assert_blocked "$VG create flutter_app --project-name my_app"
assert_blocked "$VG $TE --coverage --min-coverage 100"
assert_blocked "$VG packages check licenses"
assert_blocked "cd /path && dart $TE"
assert_blocked "ENV=1 && $FL $TE --coverage"

echo ""
echo "--- Should be ALLOWED ---"
assert_allowed "dart analyze lib/foo.dart"
assert_allowed "dart format lib/foo.dart"
assert_allowed "dart pub get"
assert_allowed "dart fix --apply"
assert_allowed "$FL pub get"
assert_allowed "$FL analyze"
assert_allowed "git add lib/router.dart test/router_test.dart"
assert_allowed "dart analyze lib/foo.dart test/bar_test.dart"
assert_allowed "git commit -m 'fix dart $TE hook'"
assert_allowed "echo '$FL create is blocked'"
assert_allowed "gh pr create --body 'use dart $TE instead'"
assert_allowed "git log --grep='dart $TE'"
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
assert_allowed "grep -nE \"$VG|$FL $TE|foo\" CLAUDE.md"
assert_allowed "grep -nE \"$VG|$FL $TE\" CLAUDE.md"
assert_allowed "grep -nE \"$FL $TE|$VG|foo\" AGENTS.md"
assert_allowed "rg '$FL $CR|dart $CR' docs/"

# A quoted phrase is a single word and runs nothing.
assert_allowed "echo \"$FL $TE\""
assert_allowed "echo '$FL $TE'"
assert_allowed "git commit -m \"ban $FL $TE | dart $TE\""

# One quote type does not toggle state inside the other.
assert_allowed "echo 'say \"$FL $TE\" now'"
assert_allowed "echo \"say '$FL $TE' now\""

# Escapes and unbalanced quotes must not throw the scanner off.
assert_allowed "echo \\\"$FL $TE\\\""
assert_allowed "grep \"$FL $TE file.md"
assert_blocked "$FL $TE --name \"my app\""

# Quote state is carried across lines, because a quoted string may span newlines.
# Without that, the second line would start unquoted and read as an invocation.
assert_allowed "$(printf 'echo "hello\n%s %s\nworld"' "$FL" "$TE")"

echo ""
echo "--- Command position ---"

# Every unquoted separator opens a fresh command position. The quoted-alternation
# cases above prove a quoted `|` is inert; these prove an unquoted one still works.
assert_blocked "echo hi; $FL $TE"
assert_blocked "echo hi | $FL $TE"
assert_blocked "echo hi & $FL $TE"
assert_blocked "test -d lib || $FL $TE"

# A prefix does not stop something from being an invocation.
assert_blocked "ENV=1 $FL $TE"
assert_blocked "CI=true COVERAGE=1 dart $TE"
assert_blocked "($FL $TE)"
assert_blocked "\$($FL $TE)"
assert_blocked "\`$FL $TE\`"
assert_blocked "echo start && ($VG $TE)"

# Any wrapper passes through to the command it runs. There is no wrapper list: pass 2
# tests every adjacent token pair, so a wrapper this suite never names is covered too,
# whatever options it takes.
assert_blocked "fvm $FL $TE"
assert_blocked "command $FL $TE"
assert_blocked "env $FL $TE"
assert_blocked "env FOO=1 $FL $TE"
assert_blocked "env -i $FL $TE"
assert_blocked "sudo $FL $TE"
assert_blocked "sudo -u ci $FL $TE"
assert_blocked "nohup $FL $TE"
assert_blocked "exec $FL $TE"
assert_blocked "time $FL $TE"
assert_blocked "timeout 60 $FL $TE"
assert_blocked "nice -n 10 $FL $TE"
assert_blocked "xargs $FL $TE"

# melos is how a VGV monorepo runs anything across its packages, options and all.
assert_blocked "melos exec -- $FL $TE"
assert_blocked "melos exec --concurrency 1 -- dart $TE"

# Shell keywords and brace groups open a command position like any other separator.
assert_blocked "if true; then $FL $TE; fi"
assert_blocked "for f in a; do $FL $TE; done"
assert_blocked "{ $FL $TE; }"
assert_blocked "while :; do dart $TE; done"

# A path-qualified binary is the same command, so match on the basename.
assert_blocked "/usr/local/bin/$FL $TE"
assert_blocked "./$FL $TE"
assert_blocked "\$FLUTTER_ROOT/bin/$FL $TE"
assert_blocked "../sdk/bin/dart $TE"

# ...but only when the wrapped command is itself blocked.
assert_allowed "fvm $FL pub get"
assert_allowed "command -v $FL"
assert_allowed "env | grep PATH"
assert_allowed "melos exec -- dart analyze"
assert_allowed "timeout 60 dart pub get"
assert_allowed "/usr/local/bin/$FL analyze"

# A wrapper with nothing after it has no pair to match.
assert_allowed "fvm"
assert_allowed "env -i"
assert_allowed "ENV=1"

# A path whose basename only resembles the command must not match.
assert_allowed "git add lib/router.dart $TE/router_${TE}.dart"
assert_allowed "cp foo.dart $TE/"
assert_allowed "ls bin/flutter_tools"

# Comments are not modelled. A blocked command on a line after a comment is still
# caught, and an apostrophe in a comment does not swallow the following lines. The cost
# is that `; dart test` inside a comment is denied -- an accepted false positive, since
# a `#` comment inside a tool call is not something the agent writes.
assert_blocked "$(printf '# a comment\n%s %s' "$FL" "$TE")"
assert_blocked "$(printf 'ls # note\ncd pkg\n%s %s' "$FL" "$TE")"
assert_allowed "$(printf '# it%ss broken\nls -la' "'")"
assert_blocked "ls # fix; dart $TE"

# `$( )` and backticks execute inside double quotes, so a blocked command there is
# caught. Single quotes and a backslash-escaped `$` really are inert and stay allowed.
assert_blocked "OUT=\"\$($FL $TE)\""
assert_blocked "echo \"\$($FL $TE)\""
assert_blocked "echo \"\`$FL $TE\`\""
assert_blocked "if [ -z \"\$(dart $TE)\" ]; then echo x; fi"
assert_allowed "echo \"\\\$($FL $TE)\""
assert_allowed "echo '\$($FL $TE)'"
assert_allowed "echo \"\$(date) building\""
assert_allowed "VAR=\"\$(ls)\"; dart analyze"

# A quoted string handed to eval or sh -c is executed, so there the quotes are
# delimiters, not data.
assert_blocked "eval \"$FL $TE\""
assert_blocked "bash -c '$FL $TE'"
assert_blocked "sh -c \"$FL $TE\""
assert_blocked "zsh -c \"cd pkg && dart $TE\""

echo ""
echo "--- Documented non-goals ---"
#
# These are allowed on purpose, and asserted so that changing one is a visible decision.
# A variable cannot be resolved without executing the command. The other three are forms
# nobody types; catching them would need a character-level shell lexer in place of the
# three substitutions, and the agent has never produced any of them.
assert_allowed "F=$FL; \$F $TE"
assert_allowed "\"$FL\" $TE"
assert_allowed "'dart' $TE"
assert_allowed "$(printf '%s \\\n%s --coverage' "$FL" "$TE")"

# A heredoc body is text, not a command position, but the scanner does not model
# heredocs and denies it. Pinned as the known limitation it is.
assert_blocked "$(printf 'cat <<EOF\n%s %s\nEOF' "$FL" "$TE")"

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
assert_tool_result deny  "Bash"  "$FL $TE"
assert_tool_result deny  "Shell" "$FL $TE"
assert_tool_result deny  "Bash"  "$VG create flutter_app"

# Anything else is not. An unrelated MCP tool can carry a `command` argument of its own,
# and reaches this hook on any host that does not apply the hooks.json matcher.
assert_tool_result aside "MCP:run_terminal_cmd" "$FL $TE"
assert_tool_result aside "MCP:browser_tabs"     "$FL $TE"
assert_tool_result aside "mcp__some-server__exec" "dart $TE --coverage"
assert_tool_result aside "Write"                "$FL $TE"

echo ""
echo "--- Deny reason follows the CLI status ---"

stub_cli 1.5.0
assert_blocked "$FL $TE"
assert_reason_contains "MCP '$TE' tool" "current CLI redirects to the MCP tool"

# The reason names what the hook actually matched, so a future misfire is self-
# explaining rather than describing an action the operator never attempted.
assert_reason_contains "Matched: $FL $TE" "deny reason quotes the matched command"

assert_blocked "fvm dart $CR my_app"
assert_reason_contains "Matched: dart $CR" "wrapper is skipped in the matched command"

# The very_good hits populate MATCHED through the same path; check one of them too.
assert_blocked "$VG packages check licenses"
assert_reason_contains "Matched: $VG packages" "very_good hits name the matched command"

stub_cli 1.2.9
assert_blocked "$FL $TE"
assert_reason_contains "too old" "outdated CLI asks for an update"

no_cli
assert_blocked "$FL $TE"
assert_reason_contains "not found" "missing CLI asks for an install"

# The MCP server starts through the same very_good shim, so redirecting to it when the
# shim cannot exec dart would be a dead end. The reason must point at PATH instead.
stub_cli
assert_blocked "$FL $TE"
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
