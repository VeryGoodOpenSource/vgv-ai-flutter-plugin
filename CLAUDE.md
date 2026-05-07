# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

VGV AI Flutter Plugin is a Claude Code plugin that provides best-practices skills for Flutter and Dart development. It is a **documentation-only repository** — there is no Dart/Flutter source code, no `pubspec.yaml`, and no tests. All value lives in the markdown skill files.

## Repository Structure

```text
.mcp.json                # MCP server configuration (Very Good CLI)
.claude-plugin/
  plugin.json          # Plugin manifest (name, version, tags)
hooks/
  hooks.json           # Hook definitions (PreToolUse and PostToolUse)
  scripts/
    analyze.sh         # Runs dart analyze on modified .dart files
    block-cli-workarounds.sh  # Prevents direct CLI bypass via Bash
    check-vgv-cli.sh   # Validates VGV CLI installed and >= 1.1.0
    format.sh          # Runs dart format on modified .dart files
    vgv-cli-common.sh  # Shared utilities for VGV CLI hook scripts
    warn-missing-mcp.sh  # Warns at session start if VGV CLI is missing/outdated
skills/
  accessibility/SKILL.md
  accessibility/reference.md
  animations/SKILL.md
  animations/references/
    explicit-animations.md
    looping-animations.md
    page-transitions.md
    staggered-animations.md
  bloc/SKILL.md
  bloc/reference.md
  create-project/SKILL.md
  dart-flutter-sdk-upgrade/SKILL.md
  internationalization/SKILL.md
  layered-architecture/SKILL.md
  layered-architecture/reference.md
  license-compliance/SKILL.md
  material-theming/SKILL.md
  navigation/SKILL.md
  static-security/SKILL.md
  static-security/reference.md
  testing/SKILL.md
  testing/reference.md
  ui-package/SKILL.md
```

## Skill File Format

Every `SKILL.md` follows this structure:

1. **YAML frontmatter** with the following fields:
   - `name` _(required)_ — prefixed with `vgv-`, lowercase letters, numbers, and hyphens only (e.g., `vgv-bloc`)
   - `description` _(required)_ — when the skill should be triggered
   - `allowed-tools` _(optional)_ — space-separated list of tools the skill may use (e.g., `Read Glob Grep`)
   - `argument-hint` _(optional)_ — placeholder hint shown to the user (e.g., `"[file-or-directory]"`)
2. **H1 title** — human-readable skill name
3. **Core Standards** — enforced constraints, always first
4. **Content sections** — architecture, code examples, workflows, anti-patterns

## Writing Conventions

- Frame standards as clear directives — no soft language ("consider", "prefer")
- Use fenced code blocks with language identifiers for all examples
- Provide complete, copy-pasteable snippets, not fragments
- Reference packages by full name (e.g., `package:mocktail`)
- Include anti-patterns alongside correct patterns when helpful
- Align pipe characters vertically in all markdown tables (enforced by markdownlint MD060)

## Adding a New Skill

1. Create `skills/<skill_name>/SKILL.md` following the format above
2. Update tags in `.claude-plugin/plugin.json`
3. Update the skills table in `README.md` (skill name must link to the `SKILL.md` file)
4. Update the repository structure in `CLAUDE.md`

## Hooks

The `hooks/` directory contains SessionStart, PreToolUse, and PostToolUse hooks defined in `hooks.json`.

### SessionStart Hooks

These run **when a session begins**:

- `warn-missing-mcp.sh` — checks if Very Good CLI is installed and >= 1.1.0; outputs a warning to Claude's context if missing or outdated (non-blocking)

### PreToolUse Hooks

These run **before** a tool call is executed:

- `mcp__very-good-cli__.*` matcher → `check-vgv-cli.sh` — validates that the Very Good CLI is installed and at version >= 1.1.0; exits 2 on failure (blocking)
- `Bash` matcher → `block-cli-workarounds.sh` — prevents direct CLI bypass of VGV CLI commands through the Bash tool; exits 2 on failure (blocking)

Both PreToolUse scripts share common utilities from `vgv-cli-common.sh`.

### PostToolUse Hooks

These run **after** a tool call completes:

- `Edit|Write` matcher → `analyze.sh` — runs `dart analyze` on the modified `.dart` file; exits 2 on failure (blocking — Claude must fix the issue)
- `Edit|Write` matcher → `format.sh` — runs `dart format` on the modified `.dart` file; always exits 0 (non-blocking)

All hook scripts require **jq** to parse the hook payload (they skip gracefully if `jq` is not installed).

## Commits

Use conventional commits: `type(scope): description`

Examples: `feat: add bloc skill`, `chore: add logo to README`
