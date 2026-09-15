#!/bin/bash
# PreToolUse hook: gate Very Good CLI MCP tool calls.
# When the CLI is installed and new enough, auto-approve the call so it is
# always allowed regardless of run mode; otherwise deny with an install/
# upgrade message instead of letting the call fail silently.

if ! command -v jq &>/dev/null; then
  echo "jq is required for check-vgv-cli hook but not found" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/vgv-cli-common.sh"

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')

# The hooks.json matcher is not a guarantee. Hosts name MCP tools differently and do not
# all treat a non-matching matcher as exclusionary, so this hook can be handed a tool it
# knows nothing about. Confirm the caller really is a Very Good CLI tool before deciding;
# anything else is none of this hook's business.
if ! is_vgv_cli_tool "$TOOL_NAME"; then
  exit 0
fi

cli_status=$(check_vgv_cli)
case "$cli_status" in
  not_installed)
    deny "Very Good CLI is not installed. This tool requires Very Good CLI >= ${MIN_VERSION}. Install with: dart pub global activate very_good_cli"
    ;;
  outdated:*)
    version="${cli_status#outdated:}"
    deny "Very Good CLI ${version} is too old. This tool requires Very Good CLI >= ${MIN_VERSION}. Update with: dart pub global activate very_good_cli"
    ;;
  unverifiable)
    # The CLI is present but its version could not be read. Stand aside rather than
    # deny a genuine call on an inconclusive check; normal permission handling applies.
    exit 0
    ;;
esac

# Version OK — auto-approve so the Very Good CLI MCP tool is always allowed,
# even under skipAutoPermissionPrompt where a non-allowlisted tool would
# otherwise fail closed and silently.
allow "Very Good CLI >= ${MIN_VERSION} verified; auto-approving Very Good CLI MCP tool call."
