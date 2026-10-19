# Finds the first shell invocation of a command the Very Good CLI MCP tools cover.
#
# Reads the whole shell call as one record and prints "<hint>\t<matched pair>" when it
# finds one, or nothing at all. Run from block-cli-workarounds.sh via `awk -f`.
#
# The model is deliberately small -- no lexer, no list of wrappers. Quoted text counts
# as data, except where the shell would still run what is inside it, and every adjacent
# word pair is tested against its basename.
#
# An awk function takes its locals as extra parameters, which is why the declarations
# below carry a gap and then a run of names that no caller ever passes.

BEGIN {
  RS = "\001"   # the whole shell call arrives as one record

  INERT = "_"   # stands in for text the shell will not run

  hint["flutter test"]       = "Do not use 'flutter test' or 'dart test'. Use the very_good_cli MCP 'test' tool instead."
  hint["dart test"]          = hint["flutter test"]
  hint["flutter create"]     = "Do not use 'flutter create' or 'dart create'. Use the very_good_cli MCP 'create' tool instead."
  hint["dart create"]        = hint["flutter create"]
  hint["very_good test"]     = "Do not use 'very_good test' via shell. Use the very_good_cli MCP 'test' tool instead."
  hint["very_good create"]   = "Do not use 'very_good create' via shell. Use the very_good_cli MCP 'create' tool instead."
  hint["very_good packages"] = "Do not use 'very_good packages' via shell. Use the very_good_cli MCP 'packages_get' or 'packages_check_licenses' tool instead."
}

# --- what the shell would treat as a command ---------------------------------

# A heredoc whose delimiter is quoted (<<'X', <<-"X") expands nothing, so its body is
# data. An unquoted <<X does expand $( ), so that body is left in place to be scanned.
function strip_quoted_heredocs(s,   lineCount, lines, i, line, kept, delimiter) {
  lineCount = split(s, lines, "\n")
  kept = ""
  for (i = 1; i <= lineCount; i++) {
    line = lines[i]

    if (delimiter != "") {
      # Inside a body: drop the line, and watch for the terminator. <<- may indent it,
      # and the delimiter is compared literally so its text is never read as a regex.
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
      if (line == delimiter) delimiter = ""
      continue
    }

    kept = kept line "\n"

    if (match(line, /<<-?[[:space:]]*('[^']+'|"[^"]+")/)) {
      delimiter = substr(line, RSTART, RLENGTH)
      sub(/^<<-?[[:space:]]*/, "", delimiter)
      gsub(/["']/, "", delimiter)
    }
  }
  return kept
}

# Replaces every quoted span in s, walking left to right. Consuming the string in order
# is what stops an apostrophe inside "..." from opening a span of its own and hiding
# everything after it. A span the shell would still read as a command keeps its
# contents; anything else becomes INERT.
function collapse_quotes(s, keepSingle, keepDouble,   out, quote, body, opensCommand) {
  out = ""
  while (match(s, /'[^']*'|"[^"]*"/)) {
    quote = substr(s, RSTART, 1)
    body  = substr(s, RSTART + 1, RLENGTH - 2)
    opensCommand = (quote == "'") ? keepSingle : keepDouble

    out = out substr(s, 1, RSTART - 1) (opensCommand ? body : INERT)
    s   = substr(s, RSTART + RLENGTH)
  }
  return out s   # an unbalanced quote matches nothing and collapses nothing
}

# The three readings of one command, in the order they are tried.
function as_written(s)      { return collapse_quotes(s, 0, 0) }   # quotes are data
function as_substitution(s) { return collapse_quotes(s, 0, 1) }   # but "$( )" runs
function as_eval_target(s)  { return collapse_quotes(s, 1, 1) }   # and eval "" runs

function runs_substitution(s) { return s ~ /\$\(|`/ }
function runs_its_argument(s) { return s ~ /(^|[^[:alnum:]_])(eval|sh|bash|zsh) / }

# --- matching ----------------------------------------------------------------

# Shell operators end a command, so turning them into a separator is enough to find
# where the next one starts. No other part of shell grammar is modelled.
function split_on_operators(s) {
  gsub(/[;&|(){}`\n]+/, " ; ", s)
  return s
}

# The first "<command> <subcommand>" pair in s that the MCP tools cover, or "".
# The command is matched on its basename, so /usr/local/bin/flutter counts as flutter
# and wrappers (fvm, melos, sudo, timeout) need no list of their own.
function blocked_pair(s,   wordCount, words, i, command, candidate) {
  s = split_on_operators(s)
  wordCount = split(s, words, /[[:space:]]+/)
  for (i = 1; i < wordCount; i++) {
    command = words[i]
    sub(/^.*\//, "", command)
    candidate = command " " words[i + 1]
    if (candidate in hint) return candidate
  }
  return ""
}

{
  gsub(/\\["'$`]/, INERT)   # a backslash-escaped quote, $ or ` is literal text
  call = strip_quoted_heredocs($0)

  pair = blocked_pair(as_written(call))
  if (pair == "" && runs_substitution(call)) pair = blocked_pair(as_substitution(call))
  if (pair == "" && runs_its_argument(call)) pair = blocked_pair(as_eval_target(call))

  if (pair != "") print hint[pair] "\t" pair
}
