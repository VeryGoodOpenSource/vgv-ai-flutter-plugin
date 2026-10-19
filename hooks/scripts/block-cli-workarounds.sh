#!/bin/bash
# PreToolUse hook: deny shell calls to CLI commands the MCP tools cover.
# To block another command, add a hint line below and a test case.

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

# Deny with a reason that fits the CLI status.
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

# The matcher lives in its own file so it reads, highlights and lints as awk rather
# than as a string embedded in this script.
MATCHER="$SCRIPT_DIR/find-blocked-invocation.awk"

if [ ! -f "$MATCHER" ]; then
  echo "block-cli-workarounds hook cannot find $MATCHER" >&2
  exit 1
fi

RESULT=$(printf '%s\n' "$COMMAND" | awk -f "$MATCHER")   # printf: echo eats -n

if [ -n "$RESULT" ]; then
  deny_with_cli_check "${RESULT%%$'\t'*}" "${RESULT#*$'\t'}"
fi

exit 0
