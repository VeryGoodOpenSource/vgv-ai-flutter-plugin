#!/bin/bash
# Shared helpers for Very Good CLI version checks and hook deny responses.

MIN_VERSION="1.5.0"

# Advice shared by the hooks, kept here so one wording reaches every caller. Each is a
# sentence the caller appends to its own first line.
DART_PATH_HINT="Put the Dart SDK bin directory on the PATH your login shell always exports, or start Claude Code from a shell where dart already resolves, then begin a new session."
REBUILD_HINT="Most often the Dart SDK changed under the installed CLI, leaving it with a snapshot built for the old SDK: run 'very_good --version' once in a terminal to rebuild it, then reconnect the server with /mcp or start a new session."

# One comparable integer from a dotted version, so a three-part comparison is a single
# test. Each part gets six digits, which no Dart package version comes near. The 10#
# prefix keeps a zero-padded part such as the 08 in 1.08.0 out of octal, which bash
# arithmetic rejects outright.
version_rank() {
  local major minor patch
  IFS='.' read -r major minor patch <<< "$1"
  echo $(( 10#$major * 10**12 + 10#$minor * 10**6 + 10#$patch ))
}

deny() {
  jq -n \
    --arg reason "$1" \
    '{
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "deny",
        permissionDecisionReason: $reason
      }
    }'
  exit 0
}

# Auto-approve the tool call, skipping the interactive permission prompt.
# A PreToolUse "allow" fires before the permission-mode check, so the call
# proceeds in every run mode (interactive, headless, skipAutoPermissionPrompt).
# Explicit deny/ask rules and managed deny lists still take precedence.
allow() {
  jq -n \
    --arg reason "$1" \
    '{
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "allow",
        permissionDecisionReason: $reason
      }
    }'
  exit 0
}

# True when the tool name identifies a Very Good CLI MCP tool. Claude Code names MCP
# tools mcp__<server>__<tool>, and mcp__plugin_<plugin>_<server>__<tool> when the plugin
# is installed from a marketplace; both carry the server segment this matches on.
is_vgv_cli_tool() {
  case "$1" in
    *very-good-cli*) return 0 ;;
    *) return 1 ;;
  esac
}

# True when the tool name identifies the host's shell tool. Claude Code calls it Bash,
# Cursor calls it Shell.
is_shell_tool() {
  case "$1" in
    Bash | Shell) return 0 ;;
    *) return 1 ;;
  esac
}

# Resolve the very_good binary. `dart pub global activate` installs it to
# ~/.pub-cache/bin, which an interactive shell adds to PATH but a hook subprocess does
# not necessarily inherit, so fall back to the pub-cache location before giving up.
resolve_vgv_bin() {
  if command -v very_good &>/dev/null; then
    command -v very_good
    return 0
  fi
  local fallback="${PUB_CACHE:-$HOME/.pub-cache}/bin/very_good"
  if [ -x "$fallback" ]; then
    echo "$fallback"
    return 0
  fi
  return 1
}

# Check Very Good CLI availability and version.
# Returns: "ok", "not_installed", "outdated:<version>", "dart_missing", or "unverifiable".
#
# The last two both mean the binary was found but its version could not be read, so
# callers must not report either as "not installed". They differ in why, and the two
# fixes have nothing in common:
#
#   dart_missing - `dart` is absent from the PATH this process inherits. The installed
#                  very_good is a shell shim that execs `dart`, so it cannot run at all.
#   unverifiable - `dart` resolves and the version still came back empty. The usual
#                  cause is a Dart SDK upgrade: the shim runs a snapshot built for the
#                  old SDK, the VM rejects it with exit code 253, and the fallback
#                  `dart pub global run` recompiles the CLI. The version stays
#                  unreadable here until that rebuild lands. PATH is not the problem.
check_vgv_cli() {
  local vgv_bin
  if ! vgv_bin=$(resolve_vgv_bin); then
    echo "not_installed"
    return
  fi
  local raw version
  raw=$("$vgv_bin" --version 2>/dev/null)
  version=$(echo "$raw" | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
  if [ -z "$version" ]; then
    # Only call it a PATH problem when dart really is absent. Blaming PATH for every
    # unreadable version sends users to edit shell profiles that were never at fault.
    if command -v dart &>/dev/null; then
      echo "unverifiable"
    else
      echo "dart_missing"
    fi
    return
  fi
  # The grep above matched three runs of digits, so both ranks are always numeric.
  if [ "$(version_rank "$version")" -lt "$(version_rank "$MIN_VERSION")" ]; then
    echo "outdated:$version"
    return
  fi
  echo "ok"
}
