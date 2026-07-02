# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

VGV AI Flutter Plugin is a Claude Code plugin that provides best-practices skills for Flutter and Dart development. There is no Dart/Flutter source code, no `pubspec.yaml`, and no tests — the plugin's value lives in the markdown skill files under `skills/`.

The repo also hosts the **Very Good Engineering website** (Astro + Starlight) under `website/`. The skills are the **single source of truth**: the public best-practices and tooling pages are generated from `SKILL.md` files by `website/scripts/generate-site-docs.mjs`. See the **Website** section below.

## Repository Structure

```text
.mcp.json                # MCP server configuration (Dart and Very Good CLI)
.claude-plugin/
  plugin.json          # Plugin manifest (name, version, keywords)
docs/
  plan/                # Planning and design documents
hooks/
  hooks.json           # Hook definitions (PreToolUse and PostToolUse)
  scripts/
    analyze.sh         # Runs dart analyze on modified .dart files
    block-cli-workarounds.sh  # Prevents direct CLI bypass via Bash
    check-vgv-cli.sh   # Validates VGV CLI installed and >= 1.3.0
    format.sh          # Runs dart format on modified .dart files
    vgv-cli-common.sh  # Shared utilities for VGV CLI hook scripts
    warn-missing-mcp.sh  # Warns at session start if VGV CLI is missing/outdated
skills/
  accessibility/SKILL.md
  accessibility/references/
  animations/SKILL.md
  animations/references/
    explicit-animations.md
    looping-animations.md
    page-transitions.md
    staggered-animations.md
  bloc/SKILL.md
  bloc/references/
  create-project/SKILL.md
  dart-flutter-sdk-upgrade/SKILL.md
  green-gate/SKILL.md
  green-gate/references/
    coverage.md
  internationalization/SKILL.md
  layered-architecture/SKILL.md
  layered-architecture/references/
  license-compliance/SKILL.md
  material-theming/SKILL.md
  navigation/SKILL.md
  static-security/SKILL.md
  static-security/references/
  testing/SKILL.md
  testing/references/
  ui-package/SKILL.md
  ui-package/reference.md
  very-good-analysis-upgrade/SKILL.md
  very-good-analysis-upgrade/reference.md
website/                 # Very Good Engineering website (Astro + Starlight)
  astro.config.mjs       # Starlight config; imports the generated sidebar
  package.json           # gen:docs / predev / prebuild scripts live here
  scripts/
    generate-site-docs.mjs  # SKILL.md (+references) -> Starlight MDX (generator)
  src/
    generated/
      sidebar.mjs        # GENERATED sidebar groups for best-practices + tooling
    content/docs/
      best-practices/    # GENERATED from knowledge skills — DO NOT EDIT
      tooling/           # GENERATED from workflow skills — DO NOT EDIT
      general-practices/ # hand-authored (philosophy, code review, conventions)
      development/       # hand-authored docs (some overlap skills, pending reconciliation)
      resources/         # hand-authored (demos, services)
```

## Skill File Format

Every `SKILL.md` follows this structure:

1. **YAML frontmatter** with the following fields:
   - `name` _(required)_ — must match the skill's folder name exactly; lowercase letters, numbers, and hyphens only (e.g., `bloc`)
   - `description` _(required)_ — when the skill should be triggered
   - `allowed-tools` _(optional)_ — space-separated list of tools the skill may use (e.g., `Read Glob Grep`)
   - `argument-hint` _(optional)_ — placeholder hint shown to the user (e.g., `"[file-or-directory]"`)
   - `web` _(optional)_ — publishes the skill to the website. A skill is published only if this block is present:

     ```yaml
     web:
       section: best-practices   # or "tooling"
       title: Bloc               # optional; defaults to a title-cased name
       order: 2                  # optional; ordering within the section
     ```

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
2. Update `keywords` **and** the `description` (marketplace text) in `.claude-plugin/plugin.json`
3. Update the skills table in `README.md` (skill name must link to the `SKILL.md` file)
4. Add the skill's slash command (e.g., `/<skill-name>`) to the **Usage** list in `README.md`
5. Add any new domain terms to the `words` list in `config/cspell.json`
6. Update the repository structure in `CLAUDE.md`
7. If the skill should appear on the website, add a `web:` frontmatter block (see **Skill File Format**), then run `npm run gen:docs` in `website/` and commit the generated pages

## Maintaining Existing Skills, Hooks, and MCP Tools

Most documentation drift comes from changing existing assets without updating the
docs that describe them. When you touch any of the following, update the matching
documentation in the same change:

- **Updating a skill's scope or description** — update the matching row in the
  `README.md` skills table so the description stays in sync.
- **Restructuring a skill's reference files** (`reference.md` ↔ `references/`) —
  update the repository structure block in `CLAUDE.md` to match the new layout.
- **Adding or changing a hook** in `hooks/hooks.json` — update the **Hooks**
  section in `README.md` (and the `## Hooks` section in `CLAUDE.md` if behavior
  changes).
- **Adding or changing an MCP tool** — update the **MCP Integration** tools table
  in `README.md`.
- **Editing any published skill's `SKILL.md` or `references/`** — regenerate the
  website with `npm run gen:docs` (from `website/`) and commit the result. CI
  fails if the committed pages are out of sync (see **Website**).

## Website

The `website/` directory is the Very Good Engineering site (Astro + Starlight),
deployed to `engineering.verygood.ventures` via GitHub Pages (`.github/workflows/deploy.yaml`).

**Skills are the source of truth.** `website/scripts/generate-site-docs.mjs`
converts every `SKILL.md` that has a `web:` frontmatter block into Starlight
Markdown:

- `web.section: best-practices` → full page at `best-practices/<name>/index.md`,
  with each `references/*.md` (and a single `reference.md`) rendered as a child page.
- `web.section: tooling` → a short summary page at `tooling/<name>.md` (purpose,
  when it triggers, how to invoke `/<name>`), not the full procedural body.
- The generator also writes `src/generated/sidebar.mjs`, imported by `astro.config.mjs`.

Rules:

- **Never hand-edit** anything under `best-practices/`, `tooling/`, or
  `src/generated/` — those are regenerated. Each file carries a `GENERATED …
  DO NOT EDIT` banner. Edit the owning skill instead, then `npm run gen:docs`.
- `npm run predev` / `npm run prebuild` run the generator automatically, so local
  dev and builds never serve stale content.
- CI (`ci.yaml` → `site` job) runs the generator and fails on any diff, so a skill
  edit that skips regeneration is caught.
- Output is deterministic (no timestamps, stable ordering); running the generator
  twice yields no diff.

**Pending reconciliation:** some hand-authored docs under
`website/src/content/docs/development/` (bloc, testing, theming, navigation,
internationalization, architecture, security) predate the skills and overlap the
generated `best-practices/` pages. Both are published for now; a follow-up pass
will migrate any unique prose/diagrams into the owning skills and remove the
duplicates.

## Hooks

The `hooks/` directory contains SessionStart, PreToolUse, and PostToolUse hooks defined in `hooks.json`.

### SessionStart Hooks

These run **when a session begins**:

- `warn-missing-mcp.sh` — checks if Very Good CLI is installed and >= 1.3.0; outputs a warning to Claude's context if missing or outdated (non-blocking)

### PreToolUse Hooks

These run **before** a tool call is executed:

- `mcp__.*very-good-cli__.*` matcher → `check-vgv-cli.sh` — auto-approves the Very Good CLI MCP tool call by returning a PreToolUse `allow` decision, so it is always permitted regardless of run mode (interactive, headless, or `skipAutoPermissionPrompt`) and never dead-ends when the tool isn't on `permissions.allow`; denies with an install/upgrade message if the CLI is missing or < 1.3.0. The `.*` in the matcher covers both the bare `mcp__very-good-cli__*` server (repo-root `.mcp.json`) and the plugin-namespaced `mcp__plugin_<plugin>_very-good-cli__*` form used when installed from a marketplace
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
