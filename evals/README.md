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
  otherwise should be ignored.

Beyond that: write prompts as a user would send them, name no skill in a prompt, grade
mechanically where you can, include the cases where the skill must say no, keep a negative
control's rubric to the absence of the skill's vocabulary, and check a grader fails in the
without-arm before trusting it.

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

- Changing `_fixture/` widens the scope to all 15 skills.
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
- **Tool execution.** The six tool-driven skills are graded on the decisions they narrate.
  `claude plugin eval` can mock MCP servers under `evals/mocks/<server>/<tool>.md`, which
  would grade them on the calls they actually make. Nothing here uses it yet.
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
