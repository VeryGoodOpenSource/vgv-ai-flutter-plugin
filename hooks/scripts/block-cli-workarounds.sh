#!/bin/bash
# PreToolUse hook: deny shell calls to CLI commands the MCP tools cover.
# To block another command, add a hint line below and a test case.

# Fail loudly rather than stand aside: a missing tool here would let every shell call
# through unchecked, and silently.
for tool in jq tr; do
  if ! command -v "$tool" &>/dev/null; then
    echo "$tool is required for block-cli-workarounds hook but not found" >&2
    exit 1
  fi
done

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

# #60 and #147 were both reports of a denial naming an action the operator never took.
# Saying where the match can come from turns a surprising denial into a legible one.
# Deliberately not phrased as "quote it and it will pass": `"flutter" test` still runs
# the command, so printing that remedy would hand out a bypass with every denial.
PAIR_MAY_BE_AN_ARGUMENT="The match is on an adjacent command and subcommand anywhere in the call, so an argument that reads like one is refused too."

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
  deny "$reason $WHOLE_CALL_REFUSED Matched: $matched. $PAIR_MAY_BE_AN_ARGUMENT"
}

# --- what the shell would treat as a command ---------------------------------
#
# No lexer, and no list of wrappers to maintain. Quoted text counts as data, except
# where the shell would still run what is inside it, and every adjacent word pair is
# tested against its basename.

INERT="_"                      # stands in for text the shell will not run
ANY_QUOTE="[\"']"

# A backslash-escaped quote, $ or ` is literal text, not a quote or an expansion.
escape_literals() {
  printf '%s' "${1//\\[\"\'\$\`]/$INERT}"
}

# A heredoc whose delimiter is quoted (<<'X', <<-"X") expands nothing, so its body is
# data. An unquoted <<X does expand $( ), so that body is left in place to be scanned.
strip_quoted_heredocs() {
  local quoted_delimiter='<<-?[[:space:]]*('"'"'[^'"'"']+'"'"'|"[^"]+")'
  local kept="" delimiter="" line trimmed

  while IFS= read -r line || [ -n "$line" ]; do
    if [ -n "$delimiter" ]; then
      # Drop the body. <<- may indent the terminator, and the delimiter is compared
      # as text so nothing in it is ever read as a pattern.
      trimmed=${line#"${line%%[![:space:]]*}"}
      trimmed=${trimmed%"${trimmed##*[![:space:]]}"}
      [ "$trimmed" = "$delimiter" ] && delimiter=""
      continue
    fi

    kept+="$line"$'\n'

    if [[ $line =~ $quoted_delimiter ]]; then
      delimiter=${BASH_REMATCH[1]}
      delimiter=${delimiter//\'/}
      delimiter=${delimiter//\"/}
    fi
  done <<< "$1"

  printf '%s' "$kept"
}

# Replaces every quoted span, walking the call from left to right. Taking the first
# quote and then its partner is the shell's own rule, so an apostrophe inside "..."
# can never open a span of its own and hide everything after it.
#
# Usage: collapse_quotes <text> <keep-single> <keep-double>. A kept span keeps its
# contents, because the shell would still run them; every other span becomes INERT.
collapse_quotes() {
  local rest=$1 keep_single=$2 keep_double=$3
  local out="" before quote body keep

  while [ -n "$rest" ]; do
    before=${rest%%$ANY_QUOTE*}
    if [ "$before" = "$rest" ]; then      # nothing quoted is left
      out+=$rest
      break
    fi

    out+=$before
    rest=${rest#"$before"}
    quote=${rest:0:1}
    rest=${rest:1}

    if [[ $rest != *"$quote"* ]]; then    # unbalanced: leave the remainder alone
      out+="$quote$rest"
      break
    fi

    body=${rest%%"$quote"*}
    rest=${rest#"$body$quote"}

    if [ "$quote" = "'" ]; then keep=$keep_single; else keep=$keep_double; fi
    if [ "$keep" = 1 ]; then out+=$body; else out+=$INERT; fi
  done

  printf '%s' "$out"
}

# The three readings of one call, in the order they are tried.
as_written()      { collapse_quotes "$1" 0 0; }   # quotes are data
as_substitution() { collapse_quotes "$1" 0 1; }   # but "$( )" runs
as_eval_target()  { collapse_quotes "$1" 1 1; }   # and eval "" runs

runs_substitution() {
  case "$1" in *'$('* | *'`'*) return 0 ;; esac
  return 1
}

runs_its_argument() {
  local re='(^|[^[:alnum:]_])(eval|sh|bash|zsh) '
  [[ $1 =~ $re ]]
}

# --- matching ----------------------------------------------------------------

# Prints the first "<command> <subcommand>" pair the MCP tools cover, or nothing.
# The command is matched on its basename, so /usr/local/bin/flutter counts as flutter
# and wrappers (fvm, melos, sudo, timeout) need no list of their own.
blocked_pair() {
  local -a words
  local line i pair

  # tr, not ${1//$OPERATOR/ }: bash 3.2 runs a bracket-class // over a long string in
  # quadratic time, which costs seconds on a command a few kilobytes long. Operators
  # become line breaks, and a pair is only ever read within one line, so no pair can
  # bridge the operator that separates two commands.
  while IFS= read -r line || [ -n "$line" ]; do   # the last line carries no newline
    read -ra words <<< "$line"

    for ((i = 0; i < ${#words[@]} - 1; i++)); do
      pair="${words[i]##*/} ${words[i + 1]}"

      case "$pair" in
        "flutter test" | "dart test" | "flutter create" | "dart create" | "very_good test" | "very_good create" | "very_good packages")
          printf '%s' "$pair"
          return 0
          ;;
      esac
    done
  done < <(printf '%s' "$1" | tr ';&|(){}`' '\n')

  return 1
}

hint_for() {
  case "$1" in
    "flutter test" | "dart test")
      printf '%s' "Do not use 'flutter test' or 'dart test'. Use the very_good_cli MCP 'test' tool instead." ;;
    "flutter create" | "dart create")
      printf '%s' "Do not use 'flutter create' or 'dart create'. Use the very_good_cli MCP 'create' tool instead." ;;
    "very_good test")
      printf '%s' "Do not use 'very_good test' via shell. Use the very_good_cli MCP 'test' tool instead." ;;
    "very_good create")
      printf '%s' "Do not use 'very_good create' via shell. Use the very_good_cli MCP 'create' tool instead." ;;
    "very_good packages")
      printf '%s' "Do not use 'very_good packages' via shell. Use the very_good_cli MCP 'packages_get' or 'packages_check_licenses' tool instead." ;;
  esac
}

CALL=$(escape_literals "$COMMAND")
CALL=$(strip_quoted_heredocs "$CALL")

PAIR=$(blocked_pair "$(as_written "$CALL")")

if [ -z "$PAIR" ] && runs_substitution "$CALL"; then
  PAIR=$(blocked_pair "$(as_substitution "$CALL")")
fi

if [ -z "$PAIR" ] && runs_its_argument "$CALL"; then
  PAIR=$(blocked_pair "$(as_eval_target "$CALL")")
fi

if [ -n "$PAIR" ]; then
  deny_with_cli_check "$(hint_for "$PAIR")" "$PAIR"
fi

exit 0
