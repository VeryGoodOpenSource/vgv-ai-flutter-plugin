# Skill Evals

Does Claude route to the skill, and does the output follow it? Cases run through
[`claude plugin eval`](https://code.claude.com/docs/en/plugin-evals) against real models.

```bash
claude plugin eval . --scaffold                       # all 100 cases, both arms
claude plugin eval . --scaffold --tag bloc            # one skill
claude plugin eval . --scaffold --ablation none       # with-plugin arm only, half the cost
```

- Claude Code **>= 2.1.269**. Earlier builds answer `plugin eval is currently in early
  access`.
- No API key locally. Runs authenticate the same way your normal session does.
- `--scaffold` is **not optional**. Without it the fixture never runs and cases fail for
  unrelated reasons.

---

## The two arms

| Arm     | What it is              | Measures                     |
| ------- | ----------------------- | ---------------------------- |
| with    | The plugin loaded       | What the plugin produces     |
| without | No plugin loaded at all | What the bare model produces |

`Δ` is the with-arm score minus the without-arm score. A grader that passes in both arms
is measuring the model, not the skill.

Each run gets a throwaway home directory, workspace, and Claude Code configuration. Your
settings, `CLAUDE.md`, MCP servers, other plugins, memory, and skills are all absent, and
the eval directory is unreadable from inside a run, so a case cannot read its own graders
or its siblings.

Exclude negative controls when you compare arms. A model with no plugin passes a "must not
invoke the skill" check for free.

---

## Writing a case

A case is a directory. Nothing registers it; it is found by being there.

```text
evals/<skill>/<case-name>/
├── prompt.md          # frontmatter: run limits; body: the prompt
├── case.yaml          # schema_version, name, and the fixture hook
├── fixture.sh         # symlink to ../../_fixture/fixture.sh — never a real file
└── graders/
    ├── skill-fired.md
    └── <one file per grader>
```

`prompt.md`:

```markdown
---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [bloc]
description: Sealed hierarchies, Equatable, and the pinned state names for a LoginBloc.
---

Write a LoginBloc for email and password authentication with submit and logout events,
and success and failure states. Output Dart code only.
```

Every case repeats that frontmatter verbatim. `claude plugin eval` has no shared-defaults
mechanism, so it is forced rather than duplication worth removing.

`case.yaml`:

```yaml
schema_version: "1.1"
name: bloc-writes-sealed-events-and-states
context:
  scaffold_script: fixture.sh
```

A grader, `graders/sealed-event-hierarchy.md`:

```markdown
---
type: regex
pattern: 'sealed class LoginEvent'
---
```

A case passes at `--threshold 0.8`, averaged across its graders and weighted. The default
threshold is `1.0`, so **pass `--threshold 0.8` or every imperfect case exits 1**.

### Grader reference

| `type`        | Options                               | Notes                                                                    |
| ------------- | ------------------------------------- | ------------------------------------------------------------------------ |
| `tool_used`   | `tool`, `input_match`, `min`, `max`   | Routing. The defaults are wrong for this suite, see below                |
| `regex`       | `pattern`, `flags`, `match`, `target` | `match: not_contains` for absence. Case-insensitivity goes in `flags: i` |
| `tool_order`  | `before`, `after`                     | Unused here                                                              |
| `file_exists` | `path`, `exists`                      | Unused here: cases are graded on the reply, not on files                 |
| `llm`         | `criteria`, `focus`                   | Frontmatter is just `type: llm`; the file body is the rubric             |
| `baseline`    | `baseline_file`, `criteria`           | Unused here                                                              |

There are **no custom-code graders**. A check that needs to execute something has no home.

A grader reads `last_message` unless its `target` says otherwise. The other targets are
`trace`, `files`, `{ source: file, path: <path> }`, and `mock_calls`, which is every call
made to a [mocked MCP tool](#mocking-the-mcp-servers).

### Routing graders

Ninety-nine of the hundred cases carry one.
`create-project-infers-dart-package-for-api-client` is the exception, and routing is
covered by that skill's other six cases. The shape is always:

```markdown
---
type: tool_used
tool: Skill
input_match: '"skill"\s*:\s*"(?:[\w-]+:)?bloc"'
weight: 3
arm: both
---
```

**`arm: both` is mandatory.** Without it a two-arm run drops every `tool_used: Skill`
grader from the score and reports it as an indicator, so a case whose skill never fires
still scores `1.00`. The cost is that the without-arm is then penalized for not having the
plugin, which inflates `Δ`. Read the two arm scores rather than `Δ` alone.

**`weight: 3` is mandatory** and nothing applies it for you. It is what sinks a case on a
routing miss alone. It does not protect the content graders: against `n` content graders
of weight 1, a single content miss scores `(n + 2) / (n + 3)`, which clears 0.8 for every
`n >= 2`. When one grader carries a case's whole point, weight that grader too.

Negative controls use the same grader with `min: 0` and `max: 0`.

### Traps that have each cost a false result

- **Rubrics are graded blind.** The judge sees the response and the criterion, not the
  prompt. Grade task success with a `regex`.
- **Only ask for what the prompt supplied.** A rubric wanting detail the prompt never gave
  can never pass.
- **The fixture must stay neutral.** It cannot be empty, or the model asks for code instead
  of writing it. It cannot name what a skill teaches either, or the no-plugin arm infers
  the conventions the case exists to measure.
- **Prompts must be self-contained.** Paste in any class a prompt refers to, and name
  pasted text as authoritative when it describes state not on disk.
- **The plugin's own SessionStart hook fires inside the run.** `warn-missing-mcp.sh`
  injects "Very Good CLI is not installed" into every with-plugin run, because the sandbox
  has no `very_good` on PATH. Tool-driven cases answer with that blocker instead of the
  question. Say in the prompt that the CLI is installed and that a startup notice saying
  otherwise should be ignored. **Mocking the server does not silence it**, because
  `check_vgv_cli` tests `command -v very_good` rather than whether the MCP tools are
  reachable. What does silence it is the `unverifiable` status: the binary resolves but its
  version cannot be read, and the hook then emits nothing. `create-project-scopes-dependency-install-to-the-new-project`
  has had the workaround sentence removed on that basis, measured 3/3 at 1.00. The other
  two prompts keep theirs, which guard against a different thing: the sandbox has no real
  toolchain, and no hook change fixes that.

Beyond that: write prompts as a user would send them, name no skill in a prompt, grade
mechanically where you can, include the cases where the skill must say no, keep a negative
control's rubric to the absence of the skill's vocabulary, and check a grader fails in the
without-arm before trusting it.

### Graders that cannot fail

A grader that passes in the no-plugin arm measures the model, not the skill. Find them by
running the case two-arm and comparing the two `graders` lists.

**One two-arm run cannot disqualify a grader.** The no-plugin arm swings hard between runs.
`accessibility-declines-gesture-detector-tap-target` had all three content graders *failing*
without the plugin on one run and all three *passing* on the next, with nothing changed in
between. Use `--runs 3` on both arms before calling a grader free, and prefer reasons that
do not depend on a score at all: redundancy, restating the prompt, and what the two arms'
text actually differs on.

**Adding beats deleting.** A free grader still fails if the skill later regresses, so it is
a regression test even when it earns no Δ. Keep every free grader that pins a Core Standard
or an anti-pattern: `no-mockito`, `no-left-anchored-insets` and `no-hand-rolled-icon-mirroring`
all pass in both arms today and all catch a real regression tomorrow. A grader pass over
these six cases deleted fifteen of them on a single free reading and had to put eleven back.

Delete only for a reason that holds without a score:

1. **A genuine duplicate.** `uses-pump-app` matched `pumpApp` beside a rubric judging the
   same thing; `names-all-rights-reserved` was the regex of the rubric next to it.
2. **It restates the prompt.** `class WeatherRepository` passes whenever the model read the
   question.
3. **It is table stakes for the format.** `testWidgets` appears in every widget test ever
   written.

Everything else gets *added to*, not cut. Read both arms' output side by side, find what
only the plugin produced, grade that, and weight it so the case turns on it.
`license-compliance-refuses-to-clear-missing-licenses` graded several ways of saying "no",
which any model says; what the plugin added was the skill's risk categorization, so that
became a weighted grader beside the ones already there.

If a case has no discriminating grader even then, the skill may genuinely teach nothing the
model does not already do, and the honest fix is the skill rather than the case.
`bloc-tests-with-bloc-test-and-mocktail` was that: both arms reached for `bloc_test` and
`mocktail` unaided, and the only real difference was that the plugin built a fresh bloc
inside `build:` while the bare model shared one from `setUp`. The skill's examples showed
that and its Core Standards never said it, so the standard was added and the grader now
tests it. That moved the case from Δ +0.38 to +0.75.

**Check that both arms answered.** A no-plugin arm that asks a clarifying question instead
of doing the work makes every grader look discriminating for one run. That is a prompt that
is not self-contained, not a result.

### Writing an `llm` rubric

Frontmatter is only `type: llm`. The body is the rubric, written as concrete PASS and FAIL
conditions with an example of each where the wording is open to reading:

```markdown
---
type: llm
---

PASS if every event class name starts with the bloc's subject and ends in a past-tense
verb, for example LoginSubmitted.

FAIL if any event name is imperative, such as SubmitLogin.
```

Match the skill's own vocabulary. A rubric asking for "rounds" against a skill that teaches
"iteration count" fails on correct answers. Keep `llm` graders for short output; for
anything long a `regex` reads the whole thing the same way every time.

---

## The fixture

Every run starts in an empty workspace. `_fixture/fixture.sh` recreates the neutral Flutter
skeleton, hooked up through `context.scaffold_script`, and runs **only with `--scaffold`**.

`context.scaffold_script` will not take a path that leaves the case directory:

```text
path "../../_fixture/fixture.sh" escapes the case directory (`..` or an absolute path)
— it must name something inside it
```

It does resolve a symlink inside the case directory, so each case's `fixture.sh` is a
symlink to the one script. A new case needs its own:

```bash
ln -s ../../_fixture/fixture.sh evals/<skill>/<case>/fixture.sh
```

**On Windows**, a checkout without `core.symlinks=true` turns each link into a text file
holding the path, and runs then fail at scaffold time. CI runs on Linux and is unaffected.

---

## Mocking the MCP servers

A run never starts the plugin's real MCP servers. `evals/mocks/<server>/<tool>.md` registers
a stand-in under the server's own name from `.mcp.json`. A server with no mock directory is
not started at all and its tools are absent, which every run reports on a `mocked:` line.

**Two things block a mocked call, and both bite before any grader runs.**

**The grant.** The published docs say a mocked tool "is allowed without an `--allow-tools`
grant". Measured on Claude Code 2.1.270, it is not. Listing the tool in a case's
`allowed_tools` is necessary and not sufficient, and without the operator grant the run
reports:

```text
not granted (missing --allow-tools grant, or a malformed entry):
mcp__very-good-cli__packages_check_licenses
```

```bash
claude plugin eval . --scaffold --allow-tools 'mcp__very-good-cli__packages_check_licenses'
```

**Two different tool names are in play, and mixing them up costs a grader.** The *bare*
`mcp__very-good-cli__<tool>` form works for the `--allow-tools` grant and for a case's
`allowed_tools`. The name the model actually invokes, and therefore the name a
`tool_used` grader has to carry, is the plugin-namespaced one:

```text
mcp__plugin_vgv-ai-flutter-plugin_very-good-cli__packages_check_licenses
```

**The plugin's own PreToolUse hook used to eat every call.** `check-vgv-cli.sh` matches
`mcp__.*very-good-cli__.*` and denied outright whenever `check_vgv_cli` did not return
`ok`, so the model received the hook's "Very Good CLI is not installed" text as the tool
result and the mock was never reached. In a run `command -v very_good` *succeeds*, because
the sandbox inherits the host PATH; `very_good --version` then returns nothing under the
run's throwaway `$HOME`, because the installed `very_good` is a shim that execs `dart`.

`check_vgv_cli` now returns `unverifiable` for exactly that case and both hooks stand
aside, so the mocks are reachable and the SessionStart notice does not fire either.
**Mocked cases therefore require a plugin that has the `unverifiable` status**; against an
older build every `very-good-cli` mock is dead.

`very-good-cli` is mocked. `dart` is not, so runs still print
`plugin_vgv-ai-flutter-plugin_dart[not started: no mock]`.

```text
evals/mocks/very-good-cli/
├── _tools.json                 # the real tools/list response
├── create.md
├── packages_check_licenses.md
├── packages_get.md
└── test.md
```

A mock file is frontmatter plus a body, and the body is the tool result:

| Key          | Default | Purpose                                                         |
| ------------ | ------- | --------------------------------------------------------------- |
| `type`       | `fixed` | `agent` instead plays the server through a judge-model call     |
| `expect`     | unset   | Per-input guard: a type name, a literal, a list, or a `/regex/` |
| `error`      | `false` | `fixed` only. Return the body as a tool error                   |
| `abort_when` | unset   | `agent` only                                                    |

`{{input.<field>}}` substitutes a call argument into the body, and
`{{file:fixtures/<name>}}` inserts a file from a `fixtures/` directory beside the mock.
`_server.md` answers several tools from one `agent` mock; a `<tool>.md` for the same tool
wins. A case's own `mocks/` directory overrides the suite's file by file.

**`expect` aborts, it does not fail.** A call that violates it ends the run at score 0,
reported as `aborted`, with no failing grader to read. Keep it to what the real server's
schema already enforces and grade argument *choices* with `tool_used` or with a `regex`
against the `mock_calls` target, which carries every mocked call, its input, and the
answer.

Every mock here is `type: fixed`. An `agent` mock answers through the judge model, so it
costs money, varies run to run, and needs a recording adopted from
`results/<timestamp>/mock-recordings/` into `.replay/` before CI repeats.

`_tools.json` is the real `tools/list` response, so a mocked tool carries the real
descriptions and input schemas rather than a permissive placeholder. Regenerate it after a
Very Good CLI release by speaking MCP to `very_good mcp` over stdio and saving the
`tools/list` result. A stale one teaches the model a schema the CLI no longer has.

`packages_check_licenses` returns a deliberately mixed result, one `GPL-3.0` and one
`unknown` among twelve permissive licenses, so a case has something real to flag.

Keep the bodies as raw tool output. A mock that already names what a skill teaches hands
the answer to the no-plugin arm, exactly as a non-neutral fixture does.

---

## Running

```bash
E="claude plugin eval . --scaffold"
$E                                             # all 100, both arms
$E --tag bloc --tag testing                    # two skills
$E --case bloc-writes-sealed-events-and-states # one case
$E --ablation none                             # with-plugin arm only, half the cost
$E --runs 3 --threshold 0.8                    # is a red case real?
```

Read the two arm scores, not the total. The without-arm is supposed to score badly.
[BASELINE.md](BASELINE.md) records the last full two-arm measurement.

**One run is not a measurement**, and these are not a merge gate.

- `--runs 3` before believing a red case. Cases drift between 2/3 and 3/3 on their own.
- A case that hit its turn cap or timed out scores 0 with **no failing grader**, which
  reads exactly like a content failure. Check the `NOTES` column, or
  `cases[].arms.with[].error` in the JSON.
- A usage limit hit mid-suite makes every later run fail the same way without marking the
  document `partial`. Check the errors.
- The suite judges with `claude-sonnet-5`, not the default small model, which marked two
  correct answers wrong on a 100-case run. Sonnet is not infallible either: when a case
  routes but scores badly, read the judge's votes in the report before editing the skill.

Measured on full runs: **$13.14** for 100 cases in one arm, **$24.93** for both arms, at
roughly **$0.12 per run**. Per-case cost varies several-fold. At `--runs 3` a two-arm sweep
is six runs per case, so budget around **$75**. `--ablation none` halves it,
`--max-cost-usd` bounds it, and `-j` up to 8 shortens wall clock.

Every run writes `results/<timestamp>/` with `aggregate-result.json` and a self-contained
`report.html`. The report is where you find out *why* a run scored low: failed graders are
expanded, and an `llm` grader shows the judge's votes and the text it judged. `results/` is
gitignored.

---

## Running in CI

`.github/workflows/evals.yaml` runs after a merge to `main`, never on a pull request,
scoped by `--tag` to the changed skills, with-plugin arm only, and `continue-on-error`.
A regression is therefore reported after it lands, and a case that has stopped
discriminating goes unnoticed until you re-check with `include_baseline`.

- Changing `_fixture/` or `mocks/` widens the scope to all 15 skills. Both are shared
  inputs, so a change to either can move any case.
- The scope job's `find` writes `-exec dirname {} \;` rather than the shorter
  `-printf '%h\n'`. `-printf` is a GNU extension that BSD `find` does not have, so the
  short form passes in CI and fails for anyone running the same job on macOS.
- A directory under `evals/` only becomes a `--tag` if it actually holds `*/case.yaml`.
  `mocks/` and `results/` sit there without being skills.
- CI needs `ANTHROPIC_API_KEY`, having no Claude Code session, and `--trust-plugin`,
  because a run with no terminal cannot answer the trust prompt.
- `--ablation none` is the only mode where a `tool_used: Skill` grader is scored by
  default. This suite sets `arm: both` so routing scores in either mode, but the two modes
  weight the baseline differently. Compare runs from one mode at a time.
- The job has a one-hour ceiling. 100 cases in one arm at `--runs 1` measured roughly 35
  minutes at `-j 4`. A full two-arm run at `--runs 3` is 600 runs and does not fit.

---

## What this does not cover

- **Dart syntax.** The previous harness parsed every fenced `dart` block through a custom
  JavaScript assertion. Native evals have no custom-code graders, so 30 cases across 11
  skills lost that check. The response text is not in `aggregate-result.json` either, only
  a `tracePath` into a sandbox deleted unless `--keep-temp` is passed. `report.html` does
  show the judged text.
- **Judge calibration.** Most graders are `llm` with no human-labelled gold set.
- **Tool execution.** `very-good-cli` is mocked and a mocked call has been driven end to
  end, so its four tools can be graded with `tool_used` or against `mock_calls`. No case
  does yet: every prompt still says the session cannot run anything, and every
  `allowed_tools` still lists only `[Read, Glob, Grep, Skill]`. Until both change, the
  tool-driven skills stay graded on the calls they narrate. The `dart` server has no mock
  at all.
- **Stable routing.** Whether a skill activates is nondeterministic, which is why routing
  is a `tool_used` grader rather than inferred from content.
- **Prose in a `SKILL.md`.** Deliberate. An earlier version asserted a hundred `contains`
  patterns against skill bodies, so a copy-edit failed the gate.
- **The skills' own surfaces.** `skills_lint` catches a link pointing at a missing file and
  a `name` that does not match its directory. Nothing catches a link resolving to the
  *wrong* file, or an `allowed-tools` name that does not exist. Four invariants are
  convention alone: `create-project` must not declare `Bash`, `green-gate` must declare it
  for parsing `coverage/lcov.info`, `.mcp.json` must keep `--enable dart_format`, and
  `flutter-reviewer` must declare no write tools.
