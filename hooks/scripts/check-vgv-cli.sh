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

cli_status=$(check_vgv_cli)
case "$cli_status" in
  not_installed)
    deny "Very Good CLI is not installed. This tool requires Very Good CLI >= ${MIN_VERSION}. Install with: dart pub global activate very_good_cli"
    ;;
  outdated:*)
    version="${cli_status#outdated:}"
    deny "Very Good CLI ${version} is too old. This tool requires Very Good CLI >= ${MIN_VERSION}. Update with: dart pub global activate very_good_cli"
    ;;
esac

# Version OK — auto-approve so the Very Good CLI MCP tool is always allowed,
# even under skipAutoPermissionPrompt where a non-allowlisted tool would
# otherwise fail closed and silently.
allow "Very Good CLI >= ${MIN_VERSION} verified; auto-approving Very Good CLI MCP tool call."
