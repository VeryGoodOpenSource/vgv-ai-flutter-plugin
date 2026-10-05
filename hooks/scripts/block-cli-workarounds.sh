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

# Decide whether the command actually *runs* one of the blocked CLIs, in two awk passes.
#
# Pass 1 makes quoting inert: quote delimiters are dropped and shell-significant
# characters inside quotes become `_`, so a quoted `|` is not a pipe and a quoted phrase
# is one word. `$( )` and backticks are the exception -- the shell runs those even inside
# double quotes -- so they reopen an unquoted region. An unquoted `#` ends the line.
#
# Pass 2 splits on the operators that open a command position and tests every adjacent
# token pair, matching the first on its basename. Testing pairs rather than the first
# word is what removes the wrapper list: `fvm`, `melos exec --`, `timeout 60`, `sudo -u
# ci`, `xargs`, shell keywords and `/usr/local/bin/flutter` all fall out of the one rule.
#
# Consequences worth knowing, each pinned by a test:
#   - an unquoted `echo flutter test` is denied; text naming a command belongs in quotes
#   - `eval "..."` and `F=flutter; $F test` pass, since catching them means reading
#     inside quotes, which is the issue #147 bug, or executing the command
#
# `printf` not `echo`, which eats a command starting with `-n`. The quote characters
# arrive via -v because a literal `'` cannot appear inside this single-quoted program.
RESULT=$(printf '%s\n' "$COMMAND" | awk -v SQ="'" -v DQ='"' '
function neutral(c) {
  if (c ~ /[;&|(){}`]/ || c ~ /[[:space:]]/) return "_"
  return c
}
BEGIN { sq = 0; dq = 0; esc = 0; bt = 0; depth = 0; acc = "" }
{
  out = ""
  len = length($0)
  for (i = 1; i <= len; i++) {
    c = substr($0, i, 1)
    if (esc)              { out = out neutral(c); esc = 0; continue }
    if (!sq && c == "\\") { esc = 1; continue }
    if (!dq && c == SQ)   { sq = !sq; continue }
    if (!sq && c == DQ)   { dq = !dq; continue }
    # `$(` and backticks run a command even inside double quotes, so they reopen an
    # unquoted region; the matching `)` or backtick restores the quote state.
    if (!sq && c == "$" && substr($0, i + 1, 1) == "(") {
      depth++; saved[depth] = dq; dq = 0; out = out "("; i++; continue
    }
    if (!sq && !dq && depth > 0 && c == ")") {
      dq = saved[depth]; depth--; out = out ")"; continue
    }
    if (!sq && c == "`") {
      if (bt) { dq = bt_dq; bt = 0 } else { bt_dq = dq; dq = 0; bt = 1 }
      out = out "`"; continue
    }
    # An unquoted `#` starting a word comments out the rest of the line. Stopping here
    # rather than scanning on keeps a `;` in a comment from opening a command position,
    # and keeps an apostrophe in a comment ("# it'"'"'s") from opening quote state that
    # would swallow every following line.
    if (!sq && !dq && c == "#" &&
        (out == "" || substr(out, length(out), 1) ~ /[[:space:]]/)) break
    if (sq || dq)         { out = out neutral(c); continue }
    out = out c
  }
  acc = acc out
  # A trailing backslash is a line continuation, and an unterminated quote swallows the
  # line break. Neither ends a command, so neither may end the record pass 2 reads.
  if (esc) next
  if (sq || dq) { acc = acc "_"; next }
  print acc; acc = ""
}
END { if (acc != "") print acc }' | awk '
{
  n = split($0, parts, /[;&|(){}`]+/)
  for (i = 1; i <= n; i++) {
    # Without this a fragment following an operator starts with a space, and the split
    # below yields an empty leading token.
    gsub(/^[[:space:]]+/, "", parts[i])
    nw = split(parts[i], w, /[[:space:]]+/)
    for (j = 1; j < nw; j++) {
      b = w[j]; s = w[j + 1]
      # Match on the basename, so a path-qualified binary is still the same command.
      sub(/^.*\//, "", b)
      hit = ""
      if ((b == "flutter" || b == "dart") && s == "create") hit = "create"
      else if ((b == "flutter" || b == "dart") && s == "test") hit = "test"
      else if (b == "very_good" && s == "create")   hit = "vg_create"
      else if (b == "very_good" && s == "test")     hit = "vg_test"
      else if (b == "very_good" && s == "packages") hit = "vg_packages"
      if (hit != "") { printf "%s\t%s %s\n", hit, b, s; exit }
    }
  }
}')

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
