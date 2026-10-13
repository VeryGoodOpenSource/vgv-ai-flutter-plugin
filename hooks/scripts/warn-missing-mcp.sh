#!/bin/bash
# SessionStart hook: warn when Very Good CLI is missing or outdated.
# Output is injected into Claude's context (not displayed in the terminal).
# Non-blocking — always exits 0.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/vgv-cli-common.sh"

# Neither unreadable-version notice may imply the server is down: hooks and the MCP client
# do not share a PATH, and under `claude plugin eval` the server is mocked and always
# answers. Say what is known and tell the session to carry on, or it opens with a false
# blocker instead of the answer. See evals/README.md.
cli_status=$(check_vgv_cli)
case "$cli_status" in
  not_installed)
    echo "⚠️ Very Good CLI is not installed. The Very Good CLI MCP server will not work without Very Good CLI >= ${MIN_VERSION}. Install with: dart pub global activate very_good_cli"
    ;;
  outdated:*)
    version="${cli_status#outdated:}"
    echo "⚠️ Very Good CLI ${version} is too old. The Very Good CLI MCP server requires >= ${MIN_VERSION}. Update with: dart pub global activate very_good_cli"
    ;;
  dart_missing)
    echo "ℹ️ Very Good CLI is installed but its version could not be verified here: dart is not on the PATH this hook inherits, so ${MIN_VERSION}+ could not be confirmed. If the Very Good CLI MCP tools answer, disregard this and carry on. If they do not, this is the likely cause. ${DART_PATH_HINT}"
    ;;
  unverifiable)
    echo "ℹ️ Very Good CLI is installed and dart is on the PATH, but the CLI did not report a version, so ${MIN_VERSION}+ could not be confirmed. If the Very Good CLI MCP tools answer, disregard this and carry on. If they fail (for example with 'Invalid SDK hash'), ${REBUILD_HINT}"
    ;;
esac

exit 0
