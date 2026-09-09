@AGENTS.md

<!-- First line is the @AGENTS.md import (Claude Code memory), not a heading. -->

## Hooks

The `hooks/` directory contains SessionStart, PreToolUse, and PostToolUse hooks defined in `hooks.json`.

### SessionStart Hooks

These run **when a session begins**:

- `warn-missing-mcp.sh` — checks if Very Good CLI is installed and >= 1.3.0; outputs a warning to Claude's context if missing or outdated (non-blocking)

### PreToolUse Hooks

These run **before** a tool call is executed:

- `mcp__.*very-good-cli__.*` matcher → `check-vgv-cli.sh` — auto-approves the Very Good CLI MCP tool call by returning a PreToolUse `allow` decision, so it is always permitted regardless of run mode (interactive, headless, or `skipAutoPermissionPrompt`) and never dead-ends when the tool isn't on `permissions.allow`; denies with an install/upgrade message if the CLI is missing or < 1.3.0. The `.*` in the matcher covers both the bare `mcp__very-good-cli__*` server (repo-root `.mcp.json`) and the plugin-namespaced `mcp__plugin_<plugin>_very-good-cli__*` form used when installed from a marketplace
- `Bash` matcher → `block-cli-workarounds.sh` — prevents direct CLI bypass of VGV CLI commands through the Bash tool; exits 2 on failure (blocking)

The first two PreToolUse hooks are plugin-level (defined in `hooks.json`) and share common utilities
from `vgv-cli-common.sh`. The following hook is **agent-scoped** — it is declared in the
`flutter-reviewer` agent's frontmatter, not in `hooks.json`, so it only fires for that agent:

- `Bash` matcher → `allow-readonly-git.sh` — restricts the `flutter-reviewer` agent's Bash to
  `git diff` / `git status` only; exits 2 on anything else, including compound-command bypass
  (blocking). Enforces the agent's read-only contract.

### PostToolUse Hooks

These run **after** a tool call completes:

- `apply_patch|Edit|Write` matcher → `analyze.sh` — runs `dart analyze` on the modified `.dart` file(s); on failure exits 2, which feeds the analyzer output back to the model as a message. `PostToolUse` runs after the tool, so this does not block or revert the edit
- `apply_patch|Edit|Write` matcher → `format.sh` — runs `dart format` on the modified `.dart` file(s); always exits 0 (non-blocking)

Both resolve the changed files with the same inline `jq` expression, handling Claude Code's
`tool_input.file_path` and Codex's `tool_input.command` (an `apply_patch` envelope, which can name
several files at once). That is the only harness-specific branch in the hook scripts, and the two
copies must stay identical.

All hook scripts require **jq** to parse the hook payload (they skip gracefully if `jq` is not installed).

### Codex

This repo installs as a Codex plugin with no Codex-specific config: the marketplace entry lives in
`very-good-claude-code-marketplace` alongside the Claude Code one, and Codex falls back to
`.claude-plugin/plugin.json` for the plugin's identity. It reads
`skills/`, `.mcp.json`, and this same `hooks/hooks.json` — resolving `${CLAUDE_PLUGIN_ROOT}` as a
compatibility alias. That is why the `PostToolUse` matcher says `apply_patch|Edit|Write`: Codex
names its file-editing tool `apply_patch`, and the extra alternative is inert on Claude Code.

The only Codex-specific asset is `codex/agents/flutter-reviewer.toml`, because Codex has no way to
bundle a subagent in a plugin — users copy it to `~/.codex/agents/` themselves. Change a hook or
the reviewer agent and both harnesses are affected — see `AGENTS.md` → Maintaining Existing
Skills, Hooks, and MCP Tools.
