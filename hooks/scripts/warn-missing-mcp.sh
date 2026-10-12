#!/bin/bash
# SessionStart hook: warn when Very Good CLI is missing or outdated.
# Output is injected into Claude's context (not displayed in the terminal).
# Non-blocking — always exits 0.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/vgv-cli-common.sh"

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
    # The very_good shim execs dart, so a PATH without dart hides the version from this
    # hook. That does not prove the server is down: hooks and the MCP client do not share
    # a PATH, and under `claude plugin eval` the server is mocked and always answers. Say
    # what is known, not what it implies, or a session spends its answer on a false blocker.
    # The advice names no shell: which startup file exports PATH differs per shell, and
    # the usual fix is launching Claude Code from a shell that already has dart.
    echo "ℹ️ Very Good CLI is installed but its version could not be verified here: dart is not on the PATH this hook inherits, so ${MIN_VERSION}+ could not be confirmed. If the Very Good CLI MCP tools answer, disregard this and carry on. If they do not, this is the likely cause. ${DART_PATH_HINT}"
    ;;
  unverifiable)
    # dart resolves, so PATH is not the problem and saying it is sends the session to
    # edit shell profiles that were never at fault. The version is unreadable for some
    # other reason, and after a Dart SDK upgrade that reason is a snapshot built for the
    # old SDK, which also leaves a server started before the upgrade on the old Dart VM.
    # Same rule as above: state what is known and tell the session to carry on if the
    # tools answer, because a mocked server under `claude plugin eval` does.
    echo "ℹ️ Very Good CLI is installed and dart is on the PATH, but the CLI did not report a version, so ${MIN_VERSION}+ could not be confirmed. If the Very Good CLI MCP tools answer, disregard this and carry on. If they fail (for example with 'Invalid SDK hash'), ${REBUILD_HINT}"
    ;;
esac

exit 0
