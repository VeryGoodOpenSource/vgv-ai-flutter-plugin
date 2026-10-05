#!/bin/bash
# PreToolUse hook: block Bash commands that bypass MCP tools.
# Denies flutter create, dart create, very_good create, very_good test,
# very_good packages, flutter test, dart test.

if ! command -v jq &>/dev/null; then
  echo "jq is required for block-cli-workarounds hook but not found" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/vgv-cli-common.sh"

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')

# Only shell commands are this hook's business. Filtering on .tool_input.command alone
# keys on a field name rather than the caller's identity, so an unrelated MCP tool that
# happens to take a `command` argument can reach this hook and be denied on a host that
# does not apply the hooks.json matcher. When a host sends no tool_name at all, fall
# through to the command check rather than silently dropping enforcement.
if [ -n "$TOOL_NAME" ] && ! is_shell_tool "$TOOL_NAME"; then
  exit 0
fi

COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if [ -z "$COMMAND" ]; then
  exit 0
fi

# A deny refuses the whole shell call, so a command chained before or after the blocked
# one (`edit-a-file && dart test`) never runs either. Without saying so, the agent
# assumes the chained command's side effect happened and carries on without it.
WHOLE_CALL_REFUSED="This whole shell call was refused, so none of it ran: run any other commands it chained in a call of their own."

# Deny with an install/upgrade message when the CLI is missing or outdated, with a PATH
# message when it is present but cannot run, and otherwise redirect to the MCP tool.
deny_with_cli_check() {
  local mcp_hint="$1"
  local cli_status reason
  cli_status=$(check_vgv_cli)
  case "$cli_status" in
    not_installed)
      reason="Very Good CLI is required but was not found. Install with: dart pub global activate very_good_cli."
      ;;
    outdated:*)
      reason="Very Good CLI ${cli_status#outdated:} is too old (requires >= ${MIN_VERSION}). Update with: dart pub global activate very_good_cli."
      ;;
    unverifiable)
      # Redirecting to the MCP tool here would be a dead end: the server starts through
      # the same very_good shim, which cannot exec dart from this PATH either.
      reason="Very Good CLI was found but could not run: dart is not on the PATH available to hooks, so the very_good_cli MCP server cannot start either. Add the Dart SDK bin directory to PATH for non-interactive shells (e.g. in ~/.zprofile) and start a new session."
      ;;
    *)
      reason="$mcp_hint"
      ;;
  esac
  # Every denial names what it matched, so a misfire is self-explaining, and says the
  # whole call was refused, so a chained command is not assumed to have run.
  deny "$reason $WHOLE_CALL_REFUSED Matched: $MATCHED"
}

# Decide whether the command actually *runs* one of the blocked CLIs: neutralize quoting,
# then look for a governed invocation in what is left.
#
# Testing every adjacent token pair, rather than only the first word of a subcommand, is
# what removes the wrapper list. `fvm`, `melos exec --`, `timeout 60`, `sudo -u ci`,
# `xargs`, shell keywords and `/usr/local/bin/flutter` all fall out of the one rule, and
# a new wrapper costs nothing. Two consequences, each pinned by a test:
#   - an unquoted `echo flutter test` is denied; text naming a command belongs in quotes
#   - `eval "..."` and `F=flutter; $F test` pass, since catching them means reading
#     inside quotes, which is the issue #147 bug, or executing the command
#
# `printf` not `echo`, which eats a command starting with `-n`. The quote characters
# arrive via -v because a literal `'` cannot appear inside a single-quoted program.
# RS is a byte no shell command contains, so the whole command is one record. Quoting
# then spans newlines for free, and a newline is just another character to classify.
# If a command ever did contain a 0x01 byte it would split into two records, and a
# token pair straddling that split would not be seen as adjacent.
sanitize_quoting='
function neutral(c) {
  if (c ~ /[;&|(){}`]/ || c ~ /[[:space:]]/) return "_"
  return c
}
BEGIN { RS = "\001" }
{
  out = ""
  len = length($0)
  for (i = 1; i <= len; i++) {
    c = substr($0, i, 1)
    # A backslash escapes the next character. Before a newline it continues the line,
    # so the pair vanishes and the two lines become one command.
    if (esc) { if (c != "\n") out = out neutral(c); esc = 0; continue }
    if (!sq && c == "\\") { esc = 1; continue }
    if (!dq && c == SQ)   { sq = !sq; continue }
    if (!sq && c == DQ)   { dq = !dq; continue }
    # A command substitution runs even inside double quotes, so it reopens a live
    # region that the matching ) or backtick closes again.
    if (!sq && c == "$" && substr($0, i + 1, 1) == "(") {
      depth++; saved[depth] = dq; dq = 0; out = out "("; i++; continue
    }
    if (!sq && !dq && depth > 0 && c == ")") {
      dq = saved[depth]; depth--; out = out ")"; continue
    }
    # A backtick is one toggle rather than a stack because backticks do not nest the
    # way $( ) does.
    if (!sq && c == "`") {
      if (bt) { dq = bt_dq; bt = 0 } else { bt_dq = dq; dq = 0; bt = 1 }
      out = out "`"; continue
    }
    # Must stay below the substitution and backtick branches, which suspend dq for the
    # live region; above them it would neutralize what the shell actually runs.
    if (sq || dq) { out = out neutral(c); continue }
    # Outside quotes a newline ends a command just as a semicolon does, and a # that
    # starts a word comments out the rest of its line. Skipping only to the newline
    # matters: the record holds every line, so stopping here would hide the rest.
    if (c == "\n") { out = out ";"; continue }
    if (c == "#" && (out == "" || substr(out, length(out), 1) ~ /[[:space:];]/)) {
      while (i < len && substr($0, i + 1, 1) != "\n") i++
      continue
    }
    out = out c
  }
  print out
}'

# Every quoted operator is inert by now, so each remaining one opens a command position.
find_invocation='
BEGIN {
  kind["flutter create"]     = "create"
  kind["dart create"]        = "create"
  kind["flutter test"]       = "test"
  kind["dart test"]          = "test"
  kind["very_good create"]   = "vg_create"
  kind["very_good test"]     = "vg_test"
  kind["very_good packages"] = "vg_packages"
}
{
  n = split($0, parts, /[;&|(){}`]+/)
  for (i = 1; i <= n; i++) {
    nw = split(parts[i], w, /[[:space:]]+/)
    for (j = 1; j < nw; j++) {
      b = w[j]
      # Match on the basename, so a path-qualified binary is the same command.
      sub(/^.*\//, "", b)
      k = kind[b " " w[j + 1]]
      if (k != "") { printf "%s\t%s %s\n", k, b, w[j + 1]; exit }
    }
  }
}'

RESULT=$(printf '%s\n' "$COMMAND" \
  | awk -v SQ="'" -v DQ='"' "$sanitize_quoting" \
  | awk "$find_invocation")

BLOCKED="${RESULT%%$'\t'*}"
MATCHED="${RESULT#*$'\t'}"

case "$BLOCKED" in
  create)      deny_with_cli_check "Do not use 'flutter create' or 'dart create'. Use the very_good_cli MCP 'create' tool instead." ;;
  test)        deny_with_cli_check "Do not use 'flutter test' or 'dart test'. Use the very_good_cli MCP 'test' tool instead." ;;
  vg_create)   deny_with_cli_check "Do not use 'very_good create' via shell. Use the very_good_cli MCP 'create' tool instead." ;;
  vg_test)     deny_with_cli_check "Do not use 'very_good test' via shell. Use the very_good_cli MCP 'test' tool instead." ;;
  vg_packages) deny_with_cli_check "Do not use 'very_good packages' via shell. Use the very_good_cli MCP 'packages_get' or 'packages_check_licenses' tool instead." ;;
esac

# Not a blocked command — allow
exit 0
