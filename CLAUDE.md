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

- `Edit|Write` matcher → `analyze.sh` — runs `dart analyze` on the modified `.dart` file; exits 2 on failure (blocking — Claude must fix the issue)
- `Edit|Write` matcher → `format.sh` — runs `dart format` on the modified `.dart` file; always exits 0 (non-blocking)

All hook scripts require **jq** to parse the hook payload (they skip gracefully if `jq` is not installed).

### Gemini CLI

`gemini/settings.json` is a copy-me config that runs these same scripts under Gemini's names:
`SessionStart` stays put, `PreToolUse` becomes `BeforeTool`, `PostToolUse` becomes `AfterTool`,
matchers become `run_shell_command`, `replace|write_file` and `mcp_very-good-cli_.*`, and timeouts
are milliseconds rather than seconds. Scripts resolve through `${VGV_PLUGIN_ROOT}`, since Gemini
has no plugin-root variable for settings-level hooks.

The scripts read `hook_event_name` off the payload and emit whichever response shape the firing
harness reads — `hookSpecificOutput.permissionDecision` for Claude Code, top-level
`decision`/`reason` for Gemini. Two things do not carry over: Gemini has no auto-approve for a
`BeforeTool` hook (so `check-vgv-cli.sh` only enforces the version gate there, and `"trust": true`
on the MCP server covers approval), and it has no agent-scoped hooks (so `allow-readonly-git.sh` is
Claude-only and `gemini/agents/flutter-reviewer.md` holds its read-only contract by granting no
shell tool at all). Change a hook or the reviewer and both harnesses are affected — see `AGENTS.md`
→ Maintaining Existing Skills, Hooks, and MCP Tools.
