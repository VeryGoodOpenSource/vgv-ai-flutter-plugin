# 🦄 Contributing to VGV AI Flutter Plugin

First of all, thank you for taking the time to contribute! 🎉👍 Before you do, please carefully read this guide.

## Getting Started

1. **Fork** the repository and clone your fork locally.
2. Create a new branch from `main` for your work.
3. Open the project in your editor of choice — any text editor works.

## Types of Contributions

| Contribution | Where |
| ------------ | ----- |
| **New skill** | `skills/<skill-name>/SKILL.md` |
| **Improve an existing skill** | Edit the relevant `skills/*/SKILL.md` or `reference.md` |
| **Eval cases** | `evals/tests/<skill-name>.yaml` |
| **Hooks** | `hooks/` directory |
| **Bug reports & feature requests** | [GitHub Issues](https://github.com/VeryGoodOpenSource/vgv-ai-flutter-plugin/issues) |

## Adding a New Skill

### 1. Create the skill file

Create `skills/<skill-name>/SKILL.md`. The file must begin with YAML frontmatter:

```yaml
---
name: <skill-name>
description: When this skill should be triggered — be specific.
allowed-tools: Read Glob Grep
argument-hint: "[file-or-directory]"   # optional
---
```

| Field | Required | Rules |
| ----- | -------- | ----- |
| `name` | Yes | Lowercase letters, numbers, and hyphens only; no leading, trailing, or consecutive hyphen; 1-64 chars; **must match the skill's directory name** (enforced in CI by `validate-skill`) |
| `description` | Yes | Describes when the skill should be triggered |
| `allowed-tools` | No | Space-separated list of tools the skill may use; a Claude Code permission hint, not a hard cap |
| `argument-hint` | No | Placeholder hint shown to the user |

After the frontmatter, structure the file as:

1. **H1 title** — human-readable skill name
2. **Core Standards** — enforced constraints, always first
3. **Content sections** — architecture, code examples, workflows, anti-patterns

Also create the Codex sidecar `skills/<skill-name>/agents/openai.yaml` with the skill-picker
metadata (see [Cross-harness portability](#cross-harness-portability) → Codex sidecar):

```yaml
interface:
  display_name: "Skill Name"
  short_description: "One short line for the picker"
```

### 2. Add eval cases

Create `evals/tests/<skill-name>.yaml` — prompts that prove the skill actually
changes what Claude produces — and register it under `tests:` in
`evals/promptfooconfig.yaml`. See [Eval Cases](#eval-cases) below.

### 3. Update `plugin.json` tags

Add relevant keywords to the `keywords` array in `.claude-plugin/plugin.json`.

### 4. Update the README skills table

Add a row to the skills table in `README.md`. The skill name must link to the `SKILL.md` file:

```markdown
| [**Skill Name**](skills/<skill-name>/SKILL.md) | Short description of what the skill covers |
```

### 5. Update `AGENTS.md` repository structure

Add the new skill directory and files to the repository structure tree in `AGENTS.md`.

## Eval Cases

Evals ask one question: does Claude route to the skill, and does the output follow it?
[promptfoo](https://www.promptfoo.dev) runs every case twice, once with this plugin
loaded and once sealed with nothing loaded, so a grader that passes in both columns is
measuring the model rather than the skill.

```bash
npx promptfoo@latest eval -c evals/promptfooconfig.yaml
```

Adding a skill means adding one case file, `evals/tests/<skill>.yaml`, registered
under `tests:` in `evals/promptfooconfig.yaml`.

[evals/README.md](evals/README.md) is the single source of truth — the case format,
the assertion reference, prerequisites, what makes a case worth having, and what
these evals deliberately do not cover. Read it before writing a case, and add new
eval documentation there rather than here.

## Skill Writing Guidelines

- **Use clear directives** — no soft language ("consider", "prefer"). Say "Use X" or "Do not use Y".
- **Fence all code blocks** with language identifiers (e.g., ` ```dart `).
- **Provide complete, copy-pasteable snippets** — not fragments.
- **Reference packages by full name** (e.g., `package:mocktail`, not just "mocktail").
- **Show anti-patterns alongside correct patterns** when helpful, so readers understand both what to do and what to avoid.

## Cross-harness portability

Skills are authored for Claude Code but target the [Agent Skills open
standard](https://agentskills.io/specification) (the `npx skills` format, supported by
many agents), so they should degrade gracefully on non-Claude harnesses such as Codex,
Gemini CLI, and OpenCode without changing Claude Code behavior. Under that standard a skill
is a **static instruction set**: the agent loads it by matching its `description`, then reads
the body — there is no argument or template substitution. `$ARGUMENTS` and
`${CLAUDE_SKILL_DIR}` are Claude Code conveniences, not spec features, so a body that uses
them must still work when they arrive unsubstituted.

**`$ARGUMENTS`** — not a spec concept; on a plain Agent Skill it is never substituted and
stays literal. Always pair it with a fallback that fires when it is empty *or still shows
the literal text* `$ARGUMENTS`:

```markdown
<feature_description>$ARGUMENTS</feature_description>

**If the feature description above is empty or still shows the literal text
`$ARGUMENTS` (the host did not substitute it), ask the user** for it (or read it
from the conversation).
```

**`${CLAUDE_SKILL_DIR}`** — no skill here uses it today (the hooks use
`${CLAUDE_PLUGIN_ROOT}`, resolved by Claude Code, not by skill bodies). If a future skill
references a bundled file, prefer the spec form — a **relative path from the skill root**
(`scripts/x.sh`) — and add a fallback for hosts that do not substitute the absolute form.

**Frontmatter** — an agent silently skips a skill whose frontmatter is malformed. Keep the
opening `---` on line 1, close the block with `---`, and include a non-empty `name:`
(kebab-case, **matching the directory name**) and `description:`. The spec also allows
`license`, `compatibility`, `metadata`, and `allowed-tools`. This plugin's Claude Code
extras (`argument-hint`, `effort`, `model`) are not spec fields, but
`npx skills` and other agents ignore unknown frontmatter keys — keep them top-level so
Claude Code reads them and nothing else breaks. (The spec's optional `skills-ref` linter is
stricter, rejecting any top-level field outside the six it allows; `npx skills` does not run
it, and nesting these extras under `metadata:` is the escape hatch if strict conformance is
ever needed.) The `Skill validation` CI job (`Flash-Brew-Digital/validate-skill@v1`) enforces
the spec (including name-matches-directory) across every skill on each pull request.

**Description length** — `description` carries the whole trigger surface, so it is the field
that grows. The spec caps it at **1024 characters and `validate-skill` treats an overrun as an
error**, not a warning, so `ignore-rules` and `fail-on-warning` will not save a long one: it
hard-fails CI. Claude Code separately truncates the listing at 1536 characters, and Codex
truncates at 1024 with no warning. Under 50 characters trips a `description-quality` warning,
which does fail the build here. Keep the field to trigger phrases and scope, and
leave pure teaching material to the body, which has no cap. Do **not** assume a sentence is
redundant because the body repeats it: routing happens before the body is ever read, so a
clause that reads like explanation may be the only thing that makes the skill findable.
`green-gate` lost its "exit only on observed numbers" clause on exactly that reasoning and
fell from 3/3 to 1/3 on the case measuring it. Re-run a skill's eval cases after trimming its
description. Every description is also concatenated into the Codex prompt on every request, so
length is a per-turn cost paid across all 15.

**MCP references** — this plugin registers two MCP servers in `.mcp.json`: `dart` (Dart and
Flutter actions) and `very-good-cli` (scaffolding, tests, license checks). On Claude Code
they are the primary execution path, and the `check-vgv-cli.sh` / `block-cli-workarounds.sh`
hooks deliberately steer the quality gates through the MCP tools instead of the raw CLI — do
not weaken that on Claude Code. Those hooks do not run on other hosts and the MCP servers may
not be connected there, so every skill that drives an MCP tool must name the equivalent
`very_good` / `dart` / `flutter` CLI command as a fallback and never block when the server is
absent. The `dart-flutter-sdk-upgrade` and `very-good-analysis-upgrade` skills already phrase
this as "use the MCP tool if available; otherwise Bash" — match that.

**Subagents** — subagents are not part of the Agent Skills standard, and no skill in this
plugin dispatches one. The `flutter-reviewer` agent (`agents/flutter-reviewer.md`) is a
Claude Code construct, ported to Gemini CLI at `gemini/agents/flutter-reviewer.md`; on a host
without a subagent mechanism its four preloaded standards
(`bloc`, `testing`, `static-security`, `accessibility`) still apply — run the review inline
against those skills instead of dispatching the agent.

**`AskUserQuestion` and `allowed-tools`** — both are Claude Code conveniences. A skill that
asks the user a structured question carries its own inline fallback: invoke whatever
equivalent user-question tool the host provides, and drop to plain numbered text only where
the host has none (see `accessibility` and `create-project`). Treat a narrow `allowed-tools`
list as a permission hint for Claude Code, not a hard cap — a skill uses whatever tools its
task needs.

**Own your references** — a skill's reference files live inside that skill's own
`references/` directory. Do not share a reference across skills by symlink or a cross-folder
`../other-skill/…` link: those do not survive every install path, and skills.sh copies each
skill on its own. Keep shared prose short enough to inline, or lift author-facing guidance
into this file rather than shipping it as a runtime reference in two places.

**Codex sidecar (`agents/openai.yaml`)** — every skill ships an `agents/openai.yaml` beside
its `SKILL.md`, carrying the Codex skill-picker metadata: `interface.display_name`, which has no
frontmatter equivalent, and `interface.short_description`, which takes precedence over the
spec-legal `metadata: short-description` key. The `SKILL.md` body stays the one
source of truth; the sidecar is thin, with no build step. Add one for every new skill.

**Gemini CLI runtime** — Gemini CLI reads the Agent Skills standard directly, so `skills/` needs
nothing: `gemini skills install <repo-url> --path skills` lands all 15. The enforcement layer does
not carry over as cleanly, and `gemini/` holds the ported pieces. Verified against Gemini CLI
0.52.0:

- **Skill discovery is the standard path.** Gemini scans `.agents/skills` and `~/.agents/skills`
  alongside its own `.gemini/skills`, so a spec-conformant skill is found with no Gemini-specific
  file. This is the whole reason `skills/` is untouched here.
- **Hook events are renamed, not absent.** `PreToolUse` is `BeforeTool`, `PostToolUse` is
  `AfterTool`, `UserPromptSubmit` is `BeforeAgent`, `Stop` is `AfterAgent`; `SessionStart` keeps its
  name. `gemini hooks migrate --from-claude` does that mapping and rewrites tool matchers
  (`Bash` → `run_shell_command`, `Edit|Write` → `replace|write_file`), which is why
  `gemini/settings.json` is generated rather than hand-written. It leaves three things wrong, all
  of which fail silently: `${CLAUDE_PLUGIN_ROOT}` is not rewritten and has no Gemini equivalent for
  settings-level hooks (hence `${VGV_PLUGIN_ROOT}`); `timeout` is copied verbatim, but Gemini reads
  **milliseconds** where Claude Code reads seconds, so a `10` becomes a 10ms budget; and MCP
  matchers keep Claude's `mcp__<server>__<tool>` naming when Gemini names them
  `mcp_<server>_<tool>`. An event name it does not recognize is skipped with a one-line warning.
- **The response shape differs, so the scripts branch.** Gemini blocks a tool on a top-level
  `{"decision": "deny", "reason": ...}` rather than
  `hookSpecificOutput.permissionDecision`. `deny()` and `allow()` in `vgv-cli-common.sh` read
  `hook_event_name` off the payload and emit whichever the firing harness reads, so one script
  serves both. A payload with no `hook_event_name` gets the Claude Code shape. Everything else is
  shared verbatim: both harnesses put the shell command in `tool_input.command` and the edited path
  in `tool_input.file_path`, so `block-cli-workarounds.sh`, `analyze.sh` and `format.sh` need no
  payload changes.
- **There is no auto-approve.** A Gemini `BeforeTool` hook can block or stand aside; it has no
  equivalent of Claude Code's `permissionDecision: "allow"`. `check-vgv-cli.sh` therefore only
  enforces the version gate on Gemini, and `"trust": true` on the MCP server covers approval. Do
  not weaken the Claude Code auto-approve to make the two match.
- **A plugin cannot ship a Gemini subagent, and the schema is strict.** Gemini loads local agents
  from `~/.gemini/agents/` or a project's `.gemini/agents/`, so
  `gemini/agents/flutter-reviewer.md` is a file users copy. It cannot be the same file as
  `agents/flutter-reviewer.md`: Gemini validates frontmatter against a strict allowlist and drops
  any agent carrying a key outside it, so `skills:` and `hooks:` are both rejected, and `tools`
  must be a YAML list of Gemini tool names (`read_file`, `glob`, `grep_search`,
  `run_shell_command`, `mcp_<server>_<tool>`). Gemini has no agent-scoped hooks and no per-agent
  argument narrowing, so the read-only contract that `allow-readonly-git.sh` holds on Claude Code
  rests on the tool list instead: the Gemini reviewer is granted no shell tool at all, which is a
  stronger guarantee, and the caller passes it the changed files in place of the `git diff` it can
  no longer run.
- **Do not weaken the Claude Code path** to make Gemini simpler. `hooks/hooks.json`,
  `.mcp.json` and `agents/flutter-reviewer.md` stay authoritative.

Nothing in CI exercises Gemini CLI, so verify a change to any of it by hand. `gemini skills list`
and a headless `gemini -p` both report what loaded — skills, agents, and hook registration — before
any model call, so pointing `GEMINI_BASE_URL` at an unreachable address is enough to read the
verdict without credentials.

**Invocation** — every skill in this plugin is **model-invoked**: the model may reach for it
autonomously when the context fits (that is the point of a best-practice skill), so neither
`disable-model-invocation` (Claude Code) nor a `policy` block (Codex) is set. All trigger
phrasing lives in `description`, and there is no `when_to_use` field: only Claude Code ever
read it, so every other host silently dropped those triggers. If you add a skill only a
human should fire, make
it **user-invoked**: set `disable-model-invocation: true` in the frontmatter and
`policy.allow_implicit_invocation: false` in its `agents/openai.yaml`, and keep the two in
sync — a skill is user-invoked in both harnesses or neither.

## Testing Locally

Editing a skill or hook and pushing straight to a PR only tells you the files
are valid, not that they work correctly. Load your working copy into a real Claude Code
session and exercise it before you commit.

### Prerequisites

- **Claude Code CLI** installed (`npm install -g @anthropic-ai/claude-code`).
- **Dart SDK** and **jq** on your `PATH` — the hooks need both.
- **Very Good CLI** ≥ 1.3.0 (`dart pub global activate very_good_cli`) for the
  Very Good CLI MCP server tools.
- **Gemini CLI** (`npm install -g @google/gemini-cli`) only if you touch the hooks
  or `gemini/`, to verify the change by hand. Everything else runs without it.

See the README [Hooks](README.md#hooks) and [MCP Integration](README.md#mcp-integration)
sections for the full prerequisite details.

### Load your local copy

From the repository root, launch Claude Code pointed at this directory:

```bash
claude --plugin-dir .
```

`--plugin-dir` loads the plugin for that session only, needs no install or
marketplace, and overrides any marketplace-installed copy of the same plugin.
`${CLAUDE_PLUGIN_ROOT}` (used throughout `hooks/hooks.json`) resolves to the
directory you pass, so the hook script paths resolve correctly.

### Verify each component loaded

| Component | How to verify |
| ----------- | --------------- |
| **Skills** | Run `/help`. Skills appear namespaced as `/vgv-ai-flutter-plugin:<skill>` (e.g. `/vgv-ai-flutter-plugin:bloc`). Invoke one to confirm it triggers. |
| **MCP servers** | Run `/mcp`. Confirm `dart` and `very-good-cli` both show connected. |
| **Hooks** | Have Claude `Edit` or `Write` a `.dart` file and confirm `analyze.sh` and `format.sh` run. Launch without Very Good CLI to see the SessionStart warning fire. |

### Iterate on changes

After editing a `SKILL.md`, a hook script, or `.mcp.json`, **restart the
`claude --plugin-dir .` session** to guarantee the change is picked up. Changes
to `.claude-plugin/plugin.json` always require a restart. Edits to the hook
`.sh` scripts take effect on the next matching tool call with no restart, since
each hook runs the script fresh.

### Rehearse the real install (optional)

To mimic the marketplace install flow without pushing anything, register a
throwaway local marketplace. Create `.claude-plugin/marketplace.json` in a temp
directory with an **absolute** path to this repo:

```jsonc
// /tmp/vgv-test-marketplace/.claude-plugin/marketplace.json
{
  "plugins": [
    {
      "name": "vgv-ai-flutter-plugin",
      "source": {
        "type": "directory",
        "path": "/ABSOLUTE/path/to/vgv-ai-flutter-plugin"
      }
    }
  ]
}
```

Then, inside a session:

```text
/plugin marketplace add /tmp/vgv-test-marketplace
/plugin install vgv-ai-flutter-plugin
```

### Validate before you push

Run the same check CI runs, from the repository root:

```bash
claude plugin validate .
```

This validates the manifest, skill frontmatter, hook JSON, MCP config, and file
references. It is static, so it confirms structure but does not replace the live checks
above.

### Troubleshooting

| Symptom | Likely cause | Fix |
| --------------------------------------- | ------------------------------------------- | ------------------------------------------------------------- |
| Skill missing from `/help` | Invalid frontmatter, or `name` doesn't match the folder | Run `claude plugin validate .` and fix the reported error |
| MCP server "executable not found" | `dart` or `very_good` not on `PATH` | Install the SDK / activate the CLI, then verify with `which` |
| Hook never fires | `jq` not installed, or script lacks `+x` / a shebang | Install `jq`; `chmod +x` the script and add `#!/bin/bash` |
| `${CLAUDE_PLUGIN_ROOT}` not resolving | Session not launched via `--plugin-dir` (or restart pending) | Restart with `claude --plugin-dir .` from the repo root |
| Local marketplace won't install | `source.path` is relative | Use an absolute path in `marketplace.json` |

## CI Checks

Every pull request runs the following checks automatically:

| Check | What it does | Config |
| ----- | ------------ | ------ |
| Markdown quality | Lints all `*.md` files with markdownlint-cli2 | `config/custom.markdownlint.jsonc` |
| Spelling | Runs cspell on all `*.md` files | `config/cspell.json` |
| Skill validation | Validates **every** `SKILL.md`'s frontmatter and structure against the Agent Skills spec, so a malformed skill fails the build instead of silently vanishing on another host | `Flash-Brew-Digital/validate-skill@v1` |
| Plugin validation | Validates and test-installs the plugin | `claude plugin validate .` |
| Script tests | Runs the hook scripts' own test suites | `hooks/scripts/*_test.sh` |

Evals do **not** run on a pull request. They call real models, so they run after a merge
to `main` instead, scoped to the skills that changed:

| Check | What it does | Config |
| ----- | ------------ | ------ |
| Evals (post-merge) | Runs the eval cases for the changed skills, `with-skill` column only. Advisory, never blocking | `.github/workflows/evals.yaml` |

That means a regression is reported after the merge rather than before it, which is a
deliberate trade: a single eval run is too noisy to gate on, and running the full suite on
every push to a PR would cost more than it saves. Run the cases for the skill you touched
locally before opening the PR — see [Eval Cases](#eval-cases).

If the spelling check flags a legitimate word, add it to `config/cspell.json` in the `words` array.

## Commit Convention

Use [Conventional Commits](https://www.conventionalcommits.org/) with the format:

```text
type(scope): description
```

| Type | When to use | Example |
| ---- | ----------- | ------- |
| `feat` | New skill or feature | `feat: add bloc skill` |
| `fix` | Fix an error or incorrect guidance | `fix: correct GoRouter redirect example` |
| `docs` | Documentation-only change | `docs: add logo to README` |
| `chore` | Maintenance, CI, tooling | `chore: update cspell config` |
| `refactor` | Restructure without changing behavior | `refactor: reorganize testing skill sections` |
| `ci` | CI pipeline changes | `ci: add manifest validation step` |

## Pull Requests

- Branch from `main`.
- Keep PRs focused — **one skill per PR** for new skills.
- Fill out the [PR template](.github/PULL_REQUEST_TEMPLATE.md) completely.
- Ensure all CI checks pass before requesting review.
- Link any related issues in the PR description.
