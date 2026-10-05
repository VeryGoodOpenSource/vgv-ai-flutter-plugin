# Skill Evals

Does Claude route to the skill, and does the output follow it? Cases run through
[`claude plugin eval`](https://code.claude.com/docs/en/plugin-evals) against real models.

```bash
claude plugin eval . --scaffold                       # all 102 cases, both arms
claude plugin eval . --scaffold --tag bloc            # one skill
claude plugin eval . --scaffold --ablation none       # with-plugin arm only, half the cost
```

- Claude Code **>= 2.1.269**.
- No API key locally. Runs authenticate the same way your normal session does.
- `--scaffold` is **not optional**. Without it the fixture never runs and cases fail for
  unrelated reasons.

---

## The two arms

| Arm     | What it is              | Measures                     |
| ------- | ----------------------- | ---------------------------- |
| with    | The plugin loaded       | What the plugin produces     |
| without | No plugin loaded at all | What the bare model produces |

`Δ` is the with-arm score minus the without-arm score. A grader that passes in both arms is
measuring the model, not the skill.

Each run gets a throwaway home directory, workspace, and Claude Code configuration, and the
eval directory is unreadable from inside a run.

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

Write a LoginBloc for email and password authentication with submit and logout events.
Output Dart code only.
```

Every case repeats that frontmatter verbatim; there is no shared-defaults mechanism.

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
| `tool_order`  | `before`, `after`                     | `before` runs first, `after` second. Gate ordering in `green-gate` only  |
| `file_exists` | `path`, `exists`                      | Unused here: cases are graded on the reply, not on files                 |
| `llm`         | `criteria`, `focus`                   | Frontmatter is just `type: llm`; the file body is the rubric             |
| `baseline`    | `baseline_file`, `criteria`           | Unused here                                                              |

There are **no custom-code graders**.

A grader reads `last_message` unless its `target` says otherwise. The other targets are
`trace`, `files`, `{ source: file, path: <path> }`, and `mock_calls`, which is every call
made to a [mocked MCP tool](#mocking-the-mcp-servers).

### Routing graders

All but one of the 102 cases carry one:

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
grader from the score, so a case whose skill never fires still scores `1.00`. It also
penalizes the without-arm, which inflates `Δ`, so read the two arm scores rather than `Δ`.

**`weight: 3` is mandatory** and nothing applies it for you. It sinks a case on a routing
miss alone. It does not protect the content graders: against `n` content graders of weight
1, a single content miss scores `(n + 2) / (n + 3)`, which clears 0.8 for every `n >= 2`.
When one grader carries a case's whole point, weight that grader too.

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
- **Check both arms answered.** A no-plugin arm that asks a clarifying question instead of
  doing the work makes every grader look discriminating. That is a prompt that is not
  self-contained, not a result.
- **The plugin's SessionStart hook fires inside every run.** `check_vgv_cli` returns
  `unverifiable` there — `very_good` resolves on PATH but `very_good --version` answers
  nothing, because it is a shim that execs `dart` under a throwaway `$HOME`. That does not
  keep the hook quiet; it emits a notice, and an earlier wording of it asserted the MCP
  server "will not start", which is false under mocks. Cases then opened with that blocker
  instead of the answer and their rubrics failed. The notice now states only what is known
  and says to carry on if the tools answer. Re-read it before blaming a case. Two prompts still say the session cannot reach a
  real toolchain, which is a different problem and true regardless.

- **A FAIL clause can punish a better answer than the PASS clause asked for.** Three
  green-gate rubrics failed replies that did more than required: one listed every failure
  and then asked for fuller analyzer text, one offered the required test and also noted the
  method might be dead code, one stated the format rule for a run the prompt forbade. Each
  FAIL clause was narrow enough that the extra thoroughness tripped it. Write the FAIL
  clause for the wrong answer, not for any departure from the shortest right one.
- **`PASS%` in the results table is runs scoring exactly 1.00**, not runs clearing
  `--threshold`. A case at 0.90 shows `33%` while passing the threshold on every run. Read
  `SCORE` against the threshold; read `PASS%` only when hunting flaky graders.
- **Judges are not stable.** Twelve judged runs of unchanged green-gate code left no `llm`
  grader at 12/12; the range was 4/12 to 11/12. A case with several `llm` graders will fail
  something most runs whatever the skill did. When a judge fails a reply that plainly
  satisfies its rubric, convert the check to a `regex` on the skill's vocabulary rather than
  rewording the rubric.

Beyond that: write prompts as a user would send them, name no skill in a prompt, grade
mechanically where you can, include the cases where the skill must say no, and keep a
negative control's rubric to the absence of the skill's vocabulary.

### Graders that cannot fail

A grader that passes in the no-plugin arm measures the model, not the skill. Find them by
running the case two-arm and comparing the two `graders` lists.

**One two-arm run cannot disqualify a grader.** Use `--runs 3` on both arms, and prefer
reasons that do not depend on a score at all.

**Adding beats deleting.** A free grader still fails if the skill later regresses, so it is
a regression test even when it earns no Δ. Keep every free grader that pins a Core Standard
or an anti-pattern. Delete only for a reason that holds without a score:

1. **A genuine duplicate** of a grader beside it.
2. **It restates the prompt.** `class WeatherRepository` passes whenever the model read the
   question.
3. **It is table stakes for the format**, such as `testWidgets` in a widget test.

Everything else gets added to. Read both arms' output side by side, find what only the
plugin produced, grade that, and weight it so the case turns on it.

If nothing discriminates even then, the skill may teach nothing the model does not already
do, and the fix is the skill rather than the case.

### Writing an `llm` rubric

Frontmatter is only `type: llm`. The body is the rubric, as concrete PASS and FAIL
conditions with an example of each:

```markdown
---
type: llm
---

PASS if every event class name starts with the bloc's subject and ends in a past-tense
verb, for example LoginSubmitted.

FAIL if any event name is imperative, such as SubmitLogin.
```

Match the skill's own vocabulary. Keep `llm` graders for short output; for anything long a
`regex` reads the whole thing the same way every time.

---

## The fixture

Every run starts in an empty workspace. `_fixture/fixture.sh` recreates the neutral Flutter
skeleton, hooked up through `context.scaffold_script`, and runs **only with `--scaffold`**.

It writes `pubspec.yaml`, `lib/counter.dart` and `test/counter_test.dart`. The two source
files exist so a case that drives the MCP tools has something real on disk to act on, and
they are deliberately the most boring code that satisfies that: a plain class with no
Flutter import, and one `test()` with one `expect()`. Nothing there is a VGV convention,
because everything there is visible to the no-plugin arm of every other skill's cases. Do
not grow them into a widget, a bloc, a `pumpApp` or a mocked dependency.

`context.scaffold_script` will not take a path that leaves the case directory, but it does
resolve a symlink inside it, so each case's `fixture.sh` is a symlink to the one script. A
new case needs its own:

```bash
ln -s ../../_fixture/fixture.sh evals/<skill>/<case>/fixture.sh
```

**On Windows**, a checkout without `core.symlinks=true` turns each link into a text file
and runs fail at scaffold time. CI runs on Linux and is unaffected.

---

## Mocking the MCP servers

`evals/mocks/<server>/<tool>.md` registers a stand-in under the server's own name from
`.mcp.json`. A server with no mock directory is not started and its tools are absent, which
every run reports on a `mocked:` line. Real servers start only with `--allow-real-servers`
or `--mocks off`, neither of which is used here.

This applies to eval runs only. A real session still reaches the real `very_good mcp` and
`dart mcp-server` servers.

```text
evals/mocks/very-good-cli/
├── _tools.json                 # the real tools/list result
├── create.md
├── packages_check_licenses.md
├── packages_get.md
└── test.md
evals/mocks/dart/
├── _tools.json                 # the analyze_files and dart_format entries only
├── analyze_files.md
└── dart_format.md
```

Frontmatter is optional and the body is the tool result. Five of the six bodies here have
no frontmatter, which is the same as `type: fixed`.

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

Four things that are not obvious:

- **A mocked tool needs no `--allow-tools` grant and no `allowed_tools` entry.** Name it in
  `allowed_tools` and you get `not granted (missing --allow-tools grant, or a malformed
  entry)`, which means the name is unknown, not that a grant is missing.
- **Use the plugin-namespaced name** in a `tool_used` grader:
  `mcp__plugin_vgv-ai-flutter-plugin_very-good-cli__<tool>`. The bare
  `mcp__very-good-cli__<tool>` form the skills use for a real session is not valid here.
- **`expect` treats a missing field as a violation**, and a violation aborts the run at
  score 0 with no failing grader to read. Guard only what the real schema requires: here
  that is `create`, so only `create.md` carries an `expect`. Grade argument *choices* with
  `tool_used` or a `regex` against `mock_calls`.
- **`_tools.json` drives the schema the model sees.** It is the `tools/list` result, the
  object with the `tools` array. Regenerate it by speaking MCP over stdio to the server
  itself — `very_good mcp` for one, `dart mcp-server --enable dart_format` for the other —
  and capturing the `tools/list` result; a stale one teaches a schema the CLI no longer
  has. Answer the server's `roots/list` request back to the client or `dart` blocks.
- **A `_tools.json` may be narrower than the server.** `dart` exposes 15 tools; the mock
  ships the 2 `green-gate` names. That removes the listed-but-unmocked case entirely, and
  keeps `roots` out of reach — a separate tool whose real handshake a mock cannot perform.
  Adding one later is additive: capture it from the same probe, drop in a `<tool>.md`.

The mocks are reachable only when `check_vgv_cli` returns `unverifiable`. In a run
`very_good` resolves on PATH but `very_good --version` answers nothing, because it is a
shim that execs `dart` under a throwaway `$HOME`. Read as `not_installed`, the PreToolUse
hook denies the call and the model gets the hook's text as the tool result.

Every mock here is `type: fixed`. An `agent` mock answers through the judge model, so it
costs money, varies run to run, and needs a recording adopted from
`results/<timestamp>/mock-recordings/` into `.replay/` before CI repeats.

Keep mock bodies as raw tool output. A mock that names what a skill teaches hands the
answer to the no-plugin arm, exactly as a non-neutral fixture does.
`packages_check_licenses` returns one `GPL-3.0` and one `unknown` among twelve permissive
licenses, so a case has something real to flag.

**The mock set is green everywhere else**, so a case can drive every gate and reach an
exit. `analyze_files` returns no errors, `dart_format` reports `0 changed`, and `test`
passes at 100%. **Keep those numbers consistent with the fixture on disk.** `dart format`
on the seeded package really does print `Formatted 2 files (0 changed)`, and the test body
reports the one test and three executable lines the fixture actually holds. An earlier
version claimed 38 tests and 378 lines; the model read the workspace, caught the mock
lying, and refused to call the package green — so a mock that contradicts the fixture does
not merely go unread, it fails the case. A failure-path case supplies its own `mocks/`
override rather than reddening the shared set.

One body is deliberately lossy. Real `dart_format` output opens with
`dart format in <absolute root>:`, which a fixed body cannot know, so the mock drops that
line and keeps the `Formatted N files (M changed)` summary the gate is actually read
from.

**Converting a case to drive a tool invalidates every rubric that read the narration.** The
model stops describing the call and just makes it, so a blind judge sees no evidence and
fails a rubric that was passing. Four rubrics went stale this way in one pass, two of them
asserting outright that no tool was available. When you convert a case, reread every `llm`
grader on it: replace the ones that judged the described call with `tool_used`, and keep
only those judging something still in the reply.

**Driving a tool costs turns and wall clock.** A converted case does strictly more than the
prompt it replaced: it routes, calls, reads the answer, then writes the reply.
`ui-package-scaffolds-with-app-ui-package-template` measured 11 to 15 turns where the
suite's usual `max_turns: 12` and `timeout_seconds: 600` had been ample, and hit both
limits. A tool-driving case therefore carries `max_turns: 20` and `timeout_seconds: 900`.
A cap breach scores the case 0 with no failing grader, so it reads as a content failure.

**A mocked tool is not there in the no-plugin arm**, so a `tool_used` grader on one fails
for free and takes any grader that needs the tool's output with it. Unlike
`tool_used: Skill`, nothing excludes these from the score, so Δ reads as if the plugin
supplied the content when it mostly supplied the tool. Read the with-arm score.
`license-compliance-runs-check-with-full-license-info` is the worked example: 1.00 with the
plugin and 0.00 without, on three runs each.

---

## Running

```bash
E="claude plugin eval . --scaffold"
$E                                             # all 102, both arms
$E --tag bloc --tag testing                    # two skills
$E --case bloc-writes-sealed-events-and-states # one case
$E --ablation none                             # with-plugin arm only, half the cost
$E --runs 3 --threshold 0.8                    # is a red case real?
```

Read the two arm scores, not the total. The without-arm is supposed to score badly.

**One run is not a measurement**, and these are not a merge gate.

- `--runs 3` before believing a red case.
- A case that hit its turn cap or timed out scores 0 with **no failing grader**, which
  reads exactly like a content failure. Check the `NOTES` column, or
  `cases[].arms.with[].error` in the JSON.
- A usage limit hit mid-suite makes every later run fail the same way without marking the
  document `partial`. Check the errors.
- The suite judges with `claude-sonnet-5`. When a case routes but scores badly, read the
  judge's votes in the report before editing the skill.
- **The no-plugin arm swings between runs.** One two-arm run cannot disqualify a grader:
  `accessibility-declines-gesture-detector-tap-target` failed all three content graders
  without the plugin on one run and passed all three on the next.
- **`create-project` pins `model: haiku`.** Its with-arm answers on a weaker model than its
  baseline, so its Δ reads low. Routing is decided before the switch, so the pin never
  explains a routing miss.

Costs: **$13** for 102 cases in one arm, **$25** for both, roughly **$0.12 per run**. At
`--runs 3` a two-arm sweep is six runs per case, so budget around **$75**. `-j` up to 8
shortens wall clock.

Every run writes `results/<timestamp>/` with `aggregate-result.json` and a self-contained
`report.html`, which is where you find out *why* a run scored low. `results/` is gitignored.

---

## Running in CI

`.github/workflows/evals.yaml` runs after a merge to `main`, never on a pull request,
scoped by `--tag` to the changed skills, with-plugin arm only, and `continue-on-error`.

- Changing `_fixture/` or `mocks/` widens the scope to all 15 skills.
- A directory under `evals/` only becomes a `--tag` if it holds `*/case.yaml`. `mocks/` and
  `results/` sit there without being skills.
- The scope job's `find` uses `-exec dirname {} \;` rather than `-printf '%h\n'`, which is
  GNU-only and fails on macOS.
- CI needs `ANTHROPIC_API_KEY`, having no Claude Code session, and `--trust-plugin`.
- `--ablation none` and `--ablation with-without` weight the baseline differently. Compare
  runs from one mode at a time.
- The job has a one-hour ceiling. 102 cases in one arm measured roughly 35 minutes at
  `-j 4`. A two-arm run at `--runs 3` is 600 runs and does not fit.

---

## What this does not cover

- **Dart syntax.** Native evals have no custom-code graders, so 30 cases across 11 skills
  lost the fenced-block parse the previous harness did. The response text is not in
  `aggregate-result.json`, only a `tracePath` into a sandbox deleted unless `--keep-temp`
  is passed. `report.html` does show the judged text.
- **Judge calibration.** Most graders are `llm` with no human-labelled gold set.
- **Tool execution, partly.** Six cases assert a call to a mocked tool, across
  `create-project`, `green-gate`, `license-compliance` and `ui-package` — find them by
  grepping the graders for `mcp__plugin`. Every other tool-driven case is still graded on
  the calls it narrates.
- **Stable routing.** Whether a skill activates is nondeterministic, which is why routing
  is a `tool_used` grader rather than inferred from content.
- **Prose in a `SKILL.md`.** Deliberate: an earlier version asserted a hundred `contains`
  patterns against skill bodies, so a copy-edit failed the gate.
- **The skills' own surfaces.** `skills_lint` catches a link to a missing file and a `name`
  that does not match its directory. Nothing catches a link resolving to the *wrong* file,
  or an `allowed-tools` name that does not exist. Four invariants are convention alone:
  `create-project` must not declare `Bash`, `green-gate` must declare it for parsing
  `coverage/lcov.info`, `.mcp.json` must keep `--enable dart_format`, and
  `flutter-reviewer` must declare no write tools.
