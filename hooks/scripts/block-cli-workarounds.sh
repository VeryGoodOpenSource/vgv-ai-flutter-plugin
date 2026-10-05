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
  local mcp_hint="$1" matched="$2"
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
  deny "$reason $WHOLE_CALL_REFUSED Matched: $matched"
}

# Deny when the command runs a blocked CLI. Quoted text is data unless something
# executes it. Every adjacent word pair is checked, so wrappers (fvm, melos exec --,
# sudo, timeout, shell keywords, /path/to/flutter) need no list.
read -r -d '' find_invocation <<'AWK' || true
BEGIN {
  RS = "\001"   # whole command is one record
  hint["flutter test"]       = "Do not use 'flutter test' or 'dart test'. Use the very_good_cli MCP 'test' tool instead."
  hint["dart test"]          = hint["flutter test"]
  hint["flutter create"]     = "Do not use 'flutter create' or 'dart create'. Use the very_good_cli MCP 'create' tool instead."
  hint["dart create"]        = hint["flutter create"]
  hint["very_good test"]     = "Do not use 'very_good test' via shell. Use the very_good_cli MCP 'test' tool instead."
  hint["very_good create"]   = "Do not use 'very_good create' via shell. Use the very_good_cli MCP 'create' tool instead."
  hint["very_good packages"] = "Do not use 'very_good packages' via shell. Use the very_good_cli MCP 'packages_get' or 'packages_check_licenses' tool instead."
}
# First blocked "cmd sub" pair in s, or "". Extra params are awk locals.
function scan(s,   n, w, i, b, pair) {
  gsub(/[;&|(){}`\n]+/, " ; ", s)                # operators end a command
  n = split(s, w, /[[:space:]]+/)
  for (i = 1; i < n; i++) {
    b = w[i]; sub(/^.*\//, "", b)                 # basename
    pair = b " " w[i + 1]
    if (pair in hint) return pair
  }
  return ""
}
{
  gsub(/\\["'$`]/, "_")                                               # escaped: literal
  text  = $0; gsub(/'[^']*'/, "_", text); gsub(/"[^"]*"/, "_", text)  # quotes are data
  subst = $0; gsub(/'[^']*'/, "_", subst); gsub(/"/, "", subst)       # but "$( )" runs
  bare  = $0; gsub(/["']/, "", bare)                                  # and eval "" runs

  pair = scan(text)
  if (pair == "" && $0 ~ /\$\(|`/)                                pair = scan(subst)
  if (pair == "" && $0 ~ /(^|[^[:alnum:]_])(eval|sh|bash|zsh) /)  pair = scan(bare)
  if (pair != "") print hint[pair] "\t" pair
}
AWK

RESULT=$(printf '%s\n' "$COMMAND" | awk "$find_invocation")   # printf: echo eats -n

if [ -n "$RESULT" ]; then
  deny_with_cli_check "${RESULT%%$'\t'*}" "${RESULT#*$'\t'}"
fi

exit 0
