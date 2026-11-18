# VGV AI Flutter Plugin

## Project Overview

VGV AI Flutter Plugin provides best-practices skills for Flutter and Dart development. There is no Dart/Flutter source code and no `pubspec.yaml`. The skills, the `flutter-reviewer` agent and the hook scripts carry the value; the only tests are the hook scripts' shell tests and the evals.

## Repository Structure

```text
.mcp.json                # MCP server configuration (Dart and Very Good CLI)
skills_lint.yaml         # skills_lint rule severities, read by the CI Skills Lint job
.claude-plugin/
  plugin.json          # Plugin manifest (name, version, keywords)
agents/
  flutter-reviewer.md  # Read-only Flutter code reviewer subagent
assets/
  icon.png             # Plugin directory listing icon, set as `icon` in plugin.json
  readme-header.png    # README banner
docs/                  # Gitignored, local only
  plan/                # Planning and design documents
evals/                 # `claude plugin eval` suite — all 15 skills, 110 cases
  README.md            # Case format, grader reference, how to add a case
  _fixture/
    fixture.sh         # The only copy of the neutral Flutter skeleton; every case symlinks here
  mocks/               # MCP stand-ins, one directory per server name in .mcp.json
    <server>/
      _tools.json      # The tools/list result the model sees; may be narrower than the server
      <tool>.md        # Frontmatter optional; the body is the tool result
  <skill>/             # One directory per skill, named for the skill it covers
    <case-name>/       # One directory per case, named for the case
      prompt.md        # Frontmatter: run limits and tools. Body: the prompt
      case.yaml        # schema_version, name, and the scaffold hook
      fixture.sh       # Symlink to _fixture/fixture.sh
      graders/
        <name>.md      # One grader per file; frontmatter is its type and options
  results/             # Written by each run — gitignored
hooks/
  hooks.json           # Hook definitions (SessionStart, SubagentStart, PreToolUse, PostToolUse)
  scripts/
    allow-readonly-git.sh  # Restricts flutter-reviewer Bash to git diff/status
    allow-readonly-git_test.sh  # Tests for allow-readonly-git.sh
    analyze.sh         # Runs dart analyze on modified .dart files
    block-cli-workarounds.sh  # Prevents direct CLI bypass via Bash
    block-cli-workarounds_test.sh  # Tests for block-cli-workarounds.sh
    check-vgv-cli.sh   # Validates VGV CLI installed and >= 1.6.0
    check-vgv-cli_test.sh  # Tests for check-vgv-cli.sh
    format.sh          # Runs dart format on modified .dart files
    sync-vge-standards.sh  # Syncs Very Good Engineering standards into a shared cache
    sync-vge-standards_test.sh  # Tests for sync-vge-standards.sh
    vgv-cli-common.sh  # Shared utilities for VGV CLI hook scripts
    warn-missing-mcp.sh  # Warns at session start if VGV CLI is missing/outdated
    warn-missing-mcp_test.sh  # Tests for warn-missing-mcp.sh
skills/
  accessibility/SKILL.md
  accessibility/references/
    audit-templates.md
    examples.md
    platforms/android.md
    platforms/ios.md
    platforms/linux.md
    platforms/macos.md
    platforms/web.md
    platforms/windows.md
    testing.md
    wcag-criteria.md
    widget-mapping.md
  animations/SKILL.md
  animations/references/
    explicit-animations.md
    implicit-animations.md
    looping-animations.md
    page-transitions.md
    staggered-animations.md
  bloc/SKILL.md
  bloc/references/
    patterns.md
    testing.md
    widgets.md
  create-project/SKILL.md
  dart-flutter-sdk-upgrade/SKILL.md
  dart-flutter-sdk-upgrade/references/
    version-conflicts.md
  green-gate/SKILL.md
  green-gate/references/
    coverage.md
  internationalization/SKILL.md
  internationalization/references/
    directionality.md
    setup.md
  layered-architecture/SKILL.md
  layered-architecture/references/
    model-transformation.md
    pubspec.md
    testing.md
    worked-example.md
  license-compliance/SKILL.md
  material-theming/SKILL.md
  material-theming/references/
    color-scheme.md
  navigation/SKILL.md
  navigation/references/
    testing.md
    typed-routes.md
  static-security/SKILL.md
  static-security/references/
    supply-chain.md
  testing/SKILL.md
  testing/references/
    animation-testing.md
    configuration.md
    coverage.md
    golden-tests.md
    matchers.md
    mocktail.md
    test-patterns.md
    widget-tests.md
  ui-package/SKILL.md
  ui-package/reference.md
  very-good-analysis-upgrade/SKILL.md
  very-good-analysis-upgrade/references/
    lint-fixes.md
```

## Skill File Format

Every `SKILL.md` follows this structure:

1. **YAML frontmatter** with the following fields:
   - `name` _(required)_ — must match the skill's folder name exactly; lowercase letters, numbers, and hyphens only (e.g., `bloc`)
   - `description` _(required)_ — when the skill should be triggered
   - `allowed-tools` _(optional)_ — space-separated list of tools the skill may use (e.g., `Read Glob Grep`)
   - `argument-hint` _(optional)_ — placeholder hint shown to the user (e.g., `"[file-or-directory]"`)
   - `model` _(optional)_ — model to use **while the skill is active**. The override applies for
     the rest of the current turn and is not saved to settings, so a user on Opus who triggers a
     skill pinned to `sonnet` stays on sonnet until their next prompt. No skill here sets it.
     A pin weaker than the session model lowers that skill's eval Δ; it never explains a
     routing miss, since routing is decided before the switch
   - `effort` _(optional)_ — reasoning effort while the skill is active (`low`/`medium`/`high`/
     `xhigh`/`max`), overriding the session level for that turn. Seven skills here set it
2. **H1 title** — human-readable skill name
3. **Core Standards** — enforced constraints, always first
4. **Content sections** — architecture, code examples, workflows, anti-patterns

Every skill in this plugin is **model-invoked** (the model may auto-activate it), so no skill sets `disable-model-invocation`. See `CONTRIBUTING.md` → Cross-harness portability.

## Writing Conventions

- Frame standards as clear directives — no soft language ("consider", "prefer")
- Use fenced code blocks with language identifiers for all examples
- Provide complete, copy-pasteable snippets, not fragments
- Reference packages by full name (e.g., `package:mocktail`)
- Include anti-patterns alongside correct patterns when helpful
- Align pipe characters vertically in all markdown tables (enforced by markdownlint MD060)

## Adding a New Skill

1. Create `skills/<skill_name>/SKILL.md` following the format above
2. Create `evals/<skill_name>/<case_name>/` — one case directory per major workflow
   the skill covers, each with a routing grader, plus one negative-control case. Routing
   graders carry `weight: 3` **and** `arm: both`; without `arm: both` the runner drops
   them from the score in a two-arm run and a routing failure scores 1.00. Nothing has to
   be registered, and the fixture symlink is the only setup step. See `evals/README.md`
3. Update `keywords` **and** the `description` (marketplace text) in `.claude-plugin/plugin.json`
4. Update the skills table in `README.md` (skill name must link to the `SKILL.md` file)
5. Add the skill's slash command (e.g., `/<skill-name>`) to the **Usage** list in `README.md`
6. Add any new domain terms to the `words` list in `config/cspell.json`
7. Update the repository structure in `AGENTS.md`

## Adding a New Agent

Agents are subagents that Claude Code dispatches as isolated, specialized helpers (e.g., reviewers).
They live in `agents/<name>.md` at the plugin root and are **auto-discovered** — unlike skills, no
`.claude-plugin/plugin.json` change is required. An `agents/<name>.md` file registers as
`vgv-ai-flutter-plugin:<name>`.

1. Create `agents/<agent_name>.md` with YAML frontmatter:
   - `name` _(required)_ — must match the file name; lowercase letters, numbers, and hyphens only
   - `description` _(required)_ — when Claude should dispatch the agent
   - `tools` _(optional)_ — comma-separated bare tool names. The `tools` field cannot scope Bash by
     command; for a read-only agent, omit write tools (`Edit`, `Write`, `NotebookEdit`) and restrict
     Bash with an agent-scoped PreToolUse hook (see `flutter-reviewer.md`)
   - `skills` _(optional)_ — bare skill names to preload at startup (full skill content is injected)
   - `model` _(optional)_ — `inherit` to use the session model
   - `hooks` _(optional)_ — agent-scoped hooks, e.g. a PreToolUse `Bash` hook
2. Add an **Agents** table row in `README.md` (agent name links to the `agents/<name>.md` file)
3. Add any new domain terms to the `words` list in `config/cspell.json`
4. Update the repository structure in `AGENTS.md`

## Hooks

The `hooks/` directory contains SessionStart, SubagentStart, PreToolUse, and PostToolUse hooks defined in `hooks.json`.

### SessionStart Hooks

These run **when a session begins**:

- `warn-missing-mcp.sh` — checks if Very Good CLI is installed and >= 1.6.0; outputs a warning to Claude's context if missing, outdated, or silent about its version (non-blocking). It names which of the two causes it is: `dart` is not on the `PATH` hooks inherit, or a Dart SDK upgrade left a stale snapshot that `very_good --version` rebuilds
- `sync-vge-standards.sh` — syncs Very Good Engineering's published standards into the shared cache `${XDG_CACHE_HOME:-~/.cache}/very_good_engineering/bundles/` (local paths mirror `/bundles/` on the host, ETags sit next to the content, a `mkdir` lock serializes concurrent runs). Conditional GET on the manifest, then on the index, then a parallel download of only the documents whose sha256 differs; each is verified against its `sha256` and `bytes` before it is moved into place. The index ETag is saved only after every document landed, so an interrupted run resumes. `VGE_TARGET_MAJOR` at the top of the script is the major the skills are written against: a newer published major, or the target missing from `majors`, pauses the sync and prints one notice. Whenever a local copy exists it prints one line with that copy's absolute path and tells the session to open listed files with the Read tool, since skills cannot resolve `$XDG_CACHE_HOME` or the eval sandbox's `$HOME` themselves; it never prints document content. Otherwise silent, and exit 0 on every failure. Needs `curl` and `sha256sum` or `shasum`

### SubagentStart Hooks

These run **when a subagent is spawned**:

- `^vgv-ai-flutter-plugin:flutter-reviewer$` matcher → `sync-vge-standards.sh --subagent` — a subagent starts with a fresh context and never sees the session start notice, so this hands `flutter-reviewer` the same path line as `hookSpecificOutput.additionalContext`. It confirms `agent_type` from the payload, prints nothing until a local copy exists, and never touches the network or the cache

### PreToolUse Hooks

These run **before** a tool call is executed:

- `mcp__.*very-good-cli__.*` matcher → `check-vgv-cli.sh` — reads `tool_name` from the payload and exits 0 unless the caller is a Very Good CLI tool, so a host that does not apply the matcher cannot have the decision land on an unrelated tool; for its own tools it auto-approves the call by returning a PreToolUse `allow` decision, so it is always permitted regardless of run mode (interactive, headless, or `skipAutoPermissionPrompt`) and never dead-ends when the tool isn't on `permissions.allow`; denies with an install/upgrade message if the CLI is missing or < 1.6.0, and stands aside when the CLI is present but its version cannot be read, for either reason, leaving normal permission handling to apply. The `.*` in the matcher covers both the bare `mcp__very-good-cli__*` server (repo-root `.mcp.json`) and the plugin-namespaced `mcp__plugin_<plugin>_very-good-cli__*` form used when installed from a marketplace
- `Bash` matcher → `block-cli-workarounds.sh` — denies `flutter`/`dart` `test`/`create`, `dart run test` and `very_good test`/`create`/`packages` in the shell and points to the MCP tool. Quoted text is data unless `eval`, `sh -c` or `$( )` runs it. A heredoc body with a quoted delimiter (`<<'EOF'`) is data too, unless the opening line feeds it to a shell (`bash <<'EOF'`, `cat <<'EOF' | sh`), which runs it; an unquoted `<<EOF` expands, so its body is always scanned. Every adjacent word pair is checked, so wrappers (`fvm`, `melos`, `sudo`, `timeout`) and `/path/to/flutter` need no list. The denial names the match and says the whole call was refused. Pinned gaps: `"flutter" test` and `$F test` pass; an unquoted pair is denied wherever it sits, including as an argument (`echo flutter test`, `man flutter test`); narrowing the match to a command position would need the wrapper list the pair rule exists to avoid

The first two PreToolUse hooks are plugin-level (defined in `hooks.json`) and share common utilities
from `vgv-cli-common.sh`. The following hook is **agent-scoped** — it is declared in the
`flutter-reviewer` agent's frontmatter, not in `hooks.json`, so it only fires for that agent:

- `Bash` matcher → `allow-readonly-git.sh` — restricts the `flutter-reviewer` agent's Bash to
  single-line `git diff` / `git status` only; denies anything else, including compound or
  multi-line commands, shell expansion (`$`), and the `--output` / `--ext-diff` options that
  write files or run programs (blocking). Enforces the agent's read-only contract.

### PostToolUse Hooks

These run **after** a tool call completes:

- `Edit|Write` matcher → `analyze.sh` — runs `dart analyze` on the modified `.dart` file; exits 2 on failure (blocking — Claude must fix the issue)
- `Edit|Write` matcher → `format.sh` — runs `dart format` on the modified `.dart` file; always exits 0 (non-blocking)

All hook scripts require **jq** to parse the hook payload (they skip gracefully if `jq` is not installed). `block-cli-workarounds.sh` also requires **tr**, and exits 1 without either, since standing aside would drop enforcement silently.

### Hook scoping

A `matcher` in `hooks.json` is a filter, not a guarantee — hosts name tools differently and do not
all treat a non-matching matcher as exclusionary. Every hook therefore confirms from its own
payload that the call is its business before deciding, and exits 0 when it is not. Scope on
`tool_name` rather than on the presence of a `tool_input` field, since field names such as
`command` are not unique to one tool.

`hooks/scripts/*_test.sh` covers the hook scripts and runs in CI under the **Script Tests** job.
Add cases there when changing hook behavior.

## Maintaining Existing Skills, Hooks, and MCP Tools

Most documentation drift comes from changing existing assets without updating the
docs that describe them. When you touch any of the following, update the matching
documentation in the same change:

- **Updating a skill's scope or description** — update the matching row in the
  `README.md` skills table, so both stay in sync. Nothing checks them against
  each other. `description` also carries every trigger phrase and is capped at
  1024 characters, which `skills_lint` enforces as an error. Several are close
  to it, so check the current length before adding a
  trigger phrase. Keep it to
  triggers and scope, leaving pure teaching material to the body. Do not cut a
  sentence just because the body repeats it — routing happens before the body
  loads — and re-run the skill's eval cases after any trim.
- **Changing what a skill teaches** — apply the KEEP / DEMOTE / DELETE rubric in
  `CONTRIBUTING.md` → _What Belongs in a `SKILL.md`_. A `SKILL.md` carries VGV
  opinions; framework reference that Claude already knows belongs in `references/`
  or nowhere. Then run the skill's eval cases to confirm the new guidance actually
  lands in the model's output, and update any case that asserted the old behavior. A failing case after a deliberate change means the case needs
  updating; a failing case after a Claude Code or MCP server change means the skill
  does.
- **Restructuring a skill's reference files** (`reference.md` ↔ `references/`) —
  update the repository structure block in `AGENTS.md` to match the new layout, and
  update every markdown link pointing at the moved file. CI catches a link that points
  at a file that no longer exists (`check-relative-paths` in `skills_lint.yaml`), but it
  cannot tell you a link now points at the wrong file, so still read each one.
- **Adding or changing a hook** in `hooks/hooks.json` — update the **Hooks**
  section in `README.md` (and the `## Hooks` section in `AGENTS.md` if behavior
  changes).
- **Adding or changing an MCP tool** — update the **MCP Integration** tools table
  in `README.md`, and check whether any skill's `allowed-tools` names a tool that
  was renamed or removed. Nothing validates those names.

## Evals

Evals ask whether Claude routes to a skill and follows it. `evals/README.md` is the
single source of truth for the case format, the grader reference, prerequisites,
and what makes a case worth having — read it before writing a case, and put new eval
documentation there rather than here.

[`claude plugin eval`](https://code.claude.com/docs/en/plugin-evals), cases under
`evals/<skill>/<case>/`. Run with `claude plugin eval . --scaffold`. Needs Claude Code
>= 2.1.269 and uses the local session, so no API key. Read the two arm scores, not the
total: the no-plugin arm is supposed to fail.

`--scaffold` is not optional. Every run starts in an empty workspace, and without the
flag the fixture script is skipped silently and cases fail for reasons unrelated to the
skill.

Run them by hand before opening a PR. They do **not** run on a pull request, because they
call real models; `.github/workflows/evals.yaml` runs them after a merge to `main`, scoped
by `--tag` to the changed skills, with-plugin arm only, and always non-blocking. A full
run is manual (`workflow_dispatch`) and is the expensive one.

Isolation is structural rather than configured: each run gets a throwaway home,
workspace and configuration, and the eval directory is unreadable from inside a run.
Nothing about the fixture or the tool grants can leak skill content into the no-plugin
arm the way the previous harness could.

## Commits

Use conventional commits: `type(scope): description`

Examples: `feat: add bloc skill`, `chore: add logo to README`
