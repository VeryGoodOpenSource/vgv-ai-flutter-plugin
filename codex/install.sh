#!/bin/bash
# Install the VGV AI Flutter Plugin into Codex.
#
# Codex has no marketplace entry for this plugin, so the four pieces are wired up
# individually:
#
#   skills  -> ~/.agents/skills/<skill>          (symlinked, or copied with --copy)
#   MCP     -> ~/.codex/config.toml              (via `codex mcp add`)
#   hooks   -> ~/.codex/hooks.json               (merged, never overwritten)
#   agent   -> ~/.codex/agents/<agent>.toml
#
# Re-running is safe: every step replaces what a previous run installed rather
# than stacking a second copy.
#
# Usage:
#   bash codex/install.sh [options]
#
# Options:
#   --skills-dir DIR   Where to install skills (default: $HOME/.agents/skills)
#   --copy             Copy skills instead of symlinking the checkout
#   --dry-run          Print what would change and exit
#   --uninstall        Remove everything this script installs
#   -h, --help         Show this help
#
# Environment:
#   CODEX_HOME         Codex config directory (default: $HOME/.codex)

set -uo pipefail

PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
SKILLS_DIR="${HOME}/.agents/skills"
INSTALL_MODE="link"
DRY_RUN=0
UNINSTALL=0

# Handler commands this script owns. Anything else in hooks.json is left alone.
VGV_HOOK_PATTERN='hooks/scripts/(warn-missing-mcp|check-vgv-cli|block-cli-workarounds|analyze|format)\.sh'

# Print the header comment block as help text.
usage() {
  awk 'NR > 1 && /^#/ { sub(/^# ?/, ""); print; next } NR > 1 { exit }' "${BASH_SOURCE[0]}"
}

while [ $# -gt 0 ]; do
  case "$1" in
    --skills-dir) SKILLS_DIR="$2"; shift 2 ;;
    --copy)       INSTALL_MODE="copy"; shift ;;
    --dry-run)    DRY_RUN=1; shift ;;
    --uninstall)  UNINSTALL=1; shift ;;
    -h|--help)    usage; exit 0 ;;
    *) echo "unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

info() { printf '  %s\n' "$1"; }
step() { printf '\n\033[1m%s\033[0m\n' "$1"; }
warn() { printf '  \033[33mwarning\033[0m  %s\n' "$1" >&2; }
die()  { printf '\033[31merror\033[0m  %s\n' "$1" >&2; exit 1; }
run()  { if [ "$DRY_RUN" -eq 1 ]; then info "would run: $*"; else "$@"; fi; }

if ! command -v jq &>/dev/null; then
  die "jq is required (the hooks parse their payload with it). Install jq and re-run."
fi

HAS_CODEX=1
if ! command -v codex &>/dev/null; then
  HAS_CODEX=0
fi

# ---------------------------------------------------------------- skills

install_skills() {
  step "Skills -> $SKILLS_DIR"
  if [ "$DRY_RUN" -eq 0 ]; then
    mkdir -p "$SKILLS_DIR" || die "cannot create $SKILLS_DIR"
  fi
  local src name dest count=0
  for src in "$PLUGIN_ROOT"/skills/*/; do
    [ -f "$src/SKILL.md" ] || continue
    name="$(basename "$src")"
    dest="$SKILLS_DIR/$name"
    if [ "$DRY_RUN" -eq 1 ]; then
      info "would install $name ($INSTALL_MODE)"
    else
      rm -rf "$dest"
      if [ "$INSTALL_MODE" = "copy" ]; then
        cp -R "${src%/}" "$dest" || die "failed to copy $name"
      else
        ln -s "${src%/}" "$dest" || die "failed to link $name"
      fi
    fi
    count=$((count + 1))
  done
  info "$count skills ($INSTALL_MODE)"
}

uninstall_skills() {
  step "Removing skills from $SKILLS_DIR"
  local src name dest count=0
  for src in "$PLUGIN_ROOT"/skills/*/; do
    name="$(basename "$src")"
    dest="$SKILLS_DIR/$name"
    [ -e "$dest" ] || [ -L "$dest" ] || continue
    run rm -rf "$dest"
    count=$((count + 1))
  done
  info "$count skills removed"
}

# ------------------------------------------------------------------- MCP

install_mcp() {
  step "MCP servers -> $CODEX_HOME/config.toml"
  if [ "$HAS_CODEX" -eq 0 ]; then
    warn "codex is not on your PATH; skipping MCP setup."
    warn "Merge codex/config.toml into $CODEX_HOME/config.toml by hand."
    return
  fi
  run env CODEX_HOME="$CODEX_HOME" codex mcp add dart -- dart mcp-server --enable dart_format \
    || warn "could not register the dart MCP server"
  run env CODEX_HOME="$CODEX_HOME" codex mcp add very-good-cli -- very_good mcp \
    || warn "could not register the very-good-cli MCP server"
  run env CODEX_HOME="$CODEX_HOME" codex features enable hooks \
    || warn "could not pin the hooks feature (it is on by default)"
}

uninstall_mcp() {
  step "Removing MCP servers from $CODEX_HOME/config.toml"
  if [ "$HAS_CODEX" -eq 0 ]; then
    warn "codex is not on your PATH; remove [mcp_servers.dart] and"
    warn "[mcp_servers.very-good-cli] from $CODEX_HOME/config.toml by hand."
    return
  fi
  run env CODEX_HOME="$CODEX_HOME" codex mcp remove dart >/dev/null 2>&1
  run env CODEX_HOME="$CODEX_HOME" codex mcp remove very-good-cli >/dev/null 2>&1
  info "dart and very-good-cli removed"
}

# ----------------------------------------------------------------- hooks

# Merge our hook handlers into an existing hooks.json without disturbing anyone
# else's. Handlers this script installed are stripped first, so re-running
# replaces them instead of appending a duplicate.
merge_hooks() {
  local existing="$1" incoming="$2"
  jq -n \
    --slurpfile cur "$existing" \
    --slurpfile new "$incoming" \
    --arg pattern "$VGV_HOOK_PATTERN" '
      def is_vgv: (.command // "") | test($pattern);
      def strip_vgv:
        map(.hooks = ((.hooks // []) | map(select(is_vgv | not))))
        | map(select((.hooks | length) > 0));

      ($cur[0] // {}) as $base
      | ($new[0].hooks // {}) as $add
      | (
          ($base.hooks // {})
          | with_entries(.value |= strip_vgv)
          | with_entries(select((.value | length) > 0))
        ) as $stripped
      | $base
        + { hooks: (
              reduce ($add | to_entries[]) as $e ($stripped;
                .[$e.key] = ((.[$e.key] // []) + $e.value))
            ) }
    '
}

strip_hooks() {
  local existing="$1"
  jq --arg pattern "$VGV_HOOK_PATTERN" '
    def is_vgv: (.command // "") | test($pattern);
    def strip_vgv:
      map(.hooks = ((.hooks // []) | map(select(is_vgv | not))))
      | map(select((.hooks | length) > 0));
    .hooks = ((.hooks // {})
      | with_entries(.value |= strip_vgv)
      | with_entries(select((.value | length) > 0)))
  ' "$existing"
}

# Write $2 over $1, keeping a timestamped backup of whatever was there.
write_hooks_file() {
  local target="$1" content="$2"
  if [ "$DRY_RUN" -eq 1 ]; then
    info "would write $target:"
    printf '%s\n' "$content" | sed 's/^/    /'
    return
  fi
  mkdir -p "$(dirname "$target")"
  if [ -f "$target" ]; then
    local backup="$target.bak-$(date +%Y%m%d%H%M%S)"
    cp "$target" "$backup" && info "backed up to $backup"
  fi
  printf '%s\n' "$content" > "$target.tmp" && mv "$target.tmp" "$target"
}

install_hooks() {
  step "Hooks -> $CODEX_HOME/hooks.json"
  local template="$PLUGIN_ROOT/codex/hooks.json"
  [ -f "$template" ] || die "missing $template"

  # ${CLAUDE_PLUGIN_ROOT} is resolved by Claude Code and means nothing to Codex,
  # so the absolute path to this checkout is baked in at install time.
  local resolved
  resolved=$(jq --arg root "$PLUGIN_ROOT" \
    'walk(if type == "string" then gsub("__VGV_PLUGIN_ROOT__"; $root) else . end)' \
    "$template") || die "could not read $template"

  local target="$CODEX_HOME/hooks.json"
  local scratch current incoming merged
  scratch=$(mktemp -d) || die "could not create a temp directory"
  incoming="$scratch/incoming.json"
  printf '%s\n' "$resolved" > "$incoming"
  if [ -f "$target" ]; then
    current="$target"
  else
    current="$scratch/current.json"
    echo '{}' > "$current"
  fi

  merged=$(merge_hooks "$current" "$incoming")
  local status=$?
  rm -rf "$scratch"
  [ $status -eq 0 ] || die "could not merge $target"
  write_hooks_file "$target" "$merged"
  info "SessionStart, PreToolUse (2), PostToolUse (2)"
}

uninstall_hooks() {
  step "Removing hooks from $CODEX_HOME/hooks.json"
  local target="$CODEX_HOME/hooks.json"
  if [ ! -f "$target" ]; then
    info "nothing to remove"
    return
  fi
  local stripped
  stripped=$(strip_hooks "$target") || die "could not rewrite $target"
  write_hooks_file "$target" "$stripped"
}

# ----------------------------------------------------------------- agents

install_agents() {
  step "Agents -> $CODEX_HOME/agents"
  local src name count=0
  for src in "$PLUGIN_ROOT"/codex/agents/*.toml; do
    [ -f "$src" ] || continue
    name="$(basename "$src")"
    if [ "$DRY_RUN" -eq 1 ]; then
      info "would install $name"
    else
      mkdir -p "$CODEX_HOME/agents"
      cp "$src" "$CODEX_HOME/agents/$name" || die "failed to install $name"
    fi
    count=$((count + 1))
  done
  info "$count agents"
}

uninstall_agents() {
  step "Removing agents from $CODEX_HOME/agents"
  local src name count=0
  for src in "$PLUGIN_ROOT"/codex/agents/*.toml; do
    [ -f "$src" ] || continue
    name="$(basename "$src")"
    [ -f "$CODEX_HOME/agents/$name" ] || continue
    run rm -f "$CODEX_HOME/agents/$name"
    count=$((count + 1))
  done
  info "$count agents removed"
}

# ------------------------------------------------------------------- main

if [ "$UNINSTALL" -eq 1 ]; then
  printf '\033[1mUninstalling VGV AI Flutter Plugin from Codex\033[0m\n'
  info "plugin root: $PLUGIN_ROOT"
  info "codex home:  $CODEX_HOME"
  uninstall_skills
  uninstall_mcp
  uninstall_hooks
  uninstall_agents
  printf '\nDone. Restart Codex to pick up the change.\n'
  exit 0
fi

printf '\033[1mInstalling VGV AI Flutter Plugin into Codex\033[0m\n'
info "plugin root: $PLUGIN_ROOT"
info "codex home:  $CODEX_HOME"
[ "$DRY_RUN" -eq 1 ] && info "dry run — nothing will be written"

install_skills
install_mcp
install_hooks
install_agents

if ! command -v dart &>/dev/null; then
  warn "dart is not on your PATH — the analyze and format hooks will do nothing."
fi
if ! command -v very_good &>/dev/null; then
  warn "very_good is not on your PATH — install with: dart pub global activate very_good_cli"
fi

printf '\nDone. Restart Codex to pick up the change.\n'
printf 'Codex asks you to review new hooks before they run; approve them with /hooks.\n'
