# Skill Evals

Does Claude route to the skill, and does the output follow it? Cases run through
[`claude plugin eval`](https://code.claude.com/docs/en/plugin-evals) against real models.

```bash
claude plugin eval . --scaffold                       # all 100 cases, both arms
claude plugin eval . --scaffold --tag bloc            # one skill
claude plugin eval . --scaffold --ablation none       # with-plugin arm only, half the cost
```

- Claude Code **>= 2.1.269**. Earlier builds answer `plugin eval is currently in early
  access`. Check with `claude --version`.
- No API key locally. Runs authenticate the same way your normal session does.
- `--scaffold` is **not optional** here. See [The fixture](#the-fixture).

---

## The two arms

| Arm      | What it is                         | Measures                     |
| -------- | ---------------------------------- | ---------------------------- |
| with     | The plugin loaded                  | What the plugin produces     |
| without  | No plugin loaded at all            | What the bare model produces |

`Δ` is the with-arm score minus the without-arm score, and it is the number that says
whether the skill did anything. A grader that passes in both arms is measuring the model.

Isolation is structural rather than configured. Each run gets a throwaway home
directory, a throwaway workspace, and a throwaway Claude Code configuration; your
settings, `CLAUDE.md`, MCP servers, other plugins, memory, and skills are all absent, and
**the eval directory itself is unreadable from inside a run**, so a case cannot read its
own graders or its siblings. Nothing here needs the three sealing keys the previous
harness required, and the class of leak that harness shipped with is not reachable.

Exclude negative controls when you compare arms: a model with no plugin passes a
"must not invoke the skill" check for free.

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
mechanism, so this is forced by the tool rather than duplication worth removing.

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

A case passes at `--threshold 0.8`, averaged across its graders and weighted. The
default threshold is `1.0`, so **pass `--threshold 0.8` or every imperfect case exits 1**.

### Grader reference

| `type`        | Options                               | Notes                                                                     |
| ------------- | ------------------------------------- | ------------------------------------------------------------------------- |
| `tool_used`   | `tool`, `input_match`, `min`, `max`   | Routing. See below — the defaults here are wrong for this suite           |
| `regex`       | `pattern`, `flags`, `match`, `target` | `match: not_contains` for absence. Case-insensitivity goes in `flags: i`  |
| `tool_order`  | `before`, `after`                     | Unused here                                                               |
| `file_exists` | `path`, `exists`                      | Unused here: cases are graded on the reply, not on files                  |
| `llm`         | `criteria`, `focus`                   | Frontmatter is just `type: llm`; the file body is the rubric              |
| `baseline`    | `baseline_file`, `criteria`           | Unused here                                                               |

There are **no custom-code graders**. A check that needs to execute something has no home.

### Routing graders, and the trap in them

Ninety-nine of the hundred cases carry one. The exception,
`create-project-infers-dart-package-for-api-client`, grades only which template name
the answer picks, and routing is covered by that skill's other six cases. A routing
grader always looks like this:

```markdown
---
type: tool_used
tool: Skill
input_match: '"skill"\s*:\s*"(?:[\w-]+:)?bloc"'
weight: 3
arm: both
---
```

**`arm: both` is mandatory and is the single easiest thing to get wrong.** In a two-arm
run the runner excludes every `tool_used: Skill` grader from the score by default and
reports it as an indicator, on the reasoning that it can never pass without the plugin.
Measured consequence during the migration: a case whose skill fired **zero times in all
three with-runs** still scored `1.00`, with `Δ 0.00`. The routing failure was invisible.

`arm: both` buys that back, and the price is real: the without-arm is now penalized for
not having the plugin, which deflates the baseline and inflates `Δ`. The previous harness
distorted identically for the same reason, so this is parity rather than a new problem,
but it means `Δ` is not readable on its own. Read the two arm scores.

`weight: 3` is what makes a routing miss sink a case at `threshold: 0.8` on its own, and
that half works: a routing miss scores between 0.25 and 0.70 depending on case size, so
it always fails. Nothing applies the weight for you.

**Know what it costs on the content side.** Routing at weight 3 against `n` content
graders of weight 1 puts a single content miss at `(n + 2) / (n + 3)`, which clears 0.8
for every `n >= 2`:

| content graders | routing miss | one content miss | two content misses |
| --------------: | -----------: | ---------------: | -----------------: |
| 1               | 0.25 fail    | 0.75 fail        | —                  |
| 2               | 0.40 fail    | **0.80 pass**    | 0.60 fail          |
| 4               | 0.57 fail    | **0.86 pass**    | 0.71 fail          |
| 7               | 0.70 fail    | **0.90 pass**    | **0.80 pass**      |

So on all but the single-grader cases, any one content grader may fail and the case still
reports green — including the grader the case exists to measure. Two-content-grader cases
sit exactly on the line at 0.80. When a case has one grader that carries its whole
point, give that grader a weight too, or the case can pass without it.

Negative controls use the same grader with `min: 0` and `max: 0`.

### Four traps that have each cost a false result

- **Rubrics are graded blind.** The judge sees the response and the criterion, not the
  prompt. "The response fixes the loop bound" therefore scores at random. Grade task
  success with a `regex`.
- **Only ask for what the prompt supplied.** A rubric wanting per-failure detail from a
  prompt that gave none can never pass.
- **The fixture must stay neutral.** It cannot be empty, or the model asks for code
  instead of writing it. It cannot hint at what a skill teaches either: an earlier
  pubspec listed `bloc`, `flutter_bloc`, `equatable` and `mocktail`, and the no-plugin
  arm inferred the conventions from it, collapsing bloc's measured lift from +10 points
  to +1.
- **Prompts must be self-contained.** Each run starts in a workspace holding only the
  fixture, so paste in any class a prompt refers to, and name pasted text as
  authoritative when it describes state not on disk.

Beyond that: write prompts as a user would send them, name no skill in a prompt so the
routing grader stays a real routing test, grade mechanically where you can, include the
cases where the skill must say no, keep a negative control's rubric to the absence of the
skill's vocabulary, and check a grader fails in the without-arm before trusting it.

### Writing an `llm` rubric

Frontmatter is only `type: llm`. The body is the rubric, written as concrete PASS and
FAIL conditions, which is what keeps a judge verdict stable between runs:

```markdown
---
type: llm
---

PASS if every event class name starts with the bloc's subject and ends in a past-tense
verb, for example LoginSubmitted.

FAIL if any event name is imperative, such as SubmitLogin.
```

Keep `llm` graders for short output. For anything long, a `regex` reads the whole thing
the same way every time.

---

## The fixture

Every run starts in an **empty** workspace. The neutral Flutter skeleton that gives a
prompt somewhere to stand is recreated per run by `fixture.sh`, hooked up through
`context.scaffold_script`, and it runs **only when you pass `--scaffold`**. Without the
flag the script is skipped silently and cases start failing for reasons that have nothing
to do with the skill.

`context.scaffold_script` will not take a path that leaves the case directory. Measured:

```text
path "../../_fixture/fixture.sh" escapes the case directory (`..` or an absolute path)
— it must name something inside it
```

It does resolve a **symlink** inside the case directory, so each case's `fixture.sh` is a
symlink to `_fixture/fixture.sh` and there is exactly one copy of the script. Edit that
one and every case follows. A new case needs its own symlink:

```bash
ln -s ../../_fixture/fixture.sh evals/<skill>/<case>/fixture.sh
```

**On Windows**, a checkout without `core.symlinks=true` turns each link into a text file
holding the path, and runs then fail at scaffold time. `git config core.symlinks true`
followed by a fresh checkout fixes it. CI runs on Linux and is unaffected.

---

## Running

```bash
E="claude plugin eval . --scaffold"
$E                                             # all 100, both arms
$E --tag bloc --tag testing                    # two skills
$E --case bloc-writes-sealed-events-and-states # one case
$E --ablation none                             # with-plugin arm only, half the cost
$E --runs 3 --threshold 0.8                    # is a red case real?
$E --judge-model claude-sonnet-5               # when you suspect the judge, not the skill
```

Read the two arm scores, not the total. The without-arm is supposed to score badly.
[BASELINE.md](BASELINE.md) records the last full two-arm measurement, including which
graders passed with no plugin loaded and which skills fail to route.

**One run is not a measurement**, and these are not a merge gate.

- `--runs 3` is the default and it is the right default. Cases drift between 2/3 and 3/3
  on their own, and two skills were nearly "fixed" off single red runs that were noise.
- A case that hit its turn cap or timed out scores 0 with **no failing grader**, which
  reads exactly like a content failure. Check the `NOTES` column, or
  `cases[].arms.with[].error` in the JSON, before believing a red case.
- A usage limit hit mid-suite makes every later run fail the same way without marking the
  document `partial`. It looks like a cliff-edge regression. Check the errors.
- `--judge-model` defaults to a small fast model. A correct answer formatted unusually
  can be marked wrong by it; re-run with a stronger judge before editing the skill.

Cost per run was measured between **$0.055 and $0.147** across three sample runs, and the
spread is real: a case that asks for a whole theme file costs several times one that asks
for a refusal. Three runs across both arms is six runs per case, so budget roughly
**$0.35 to $0.90 per case**, putting a full two-arm suite somewhere around **$35 to $90**.
Treat it as a release check rather than an edit-loop one. `--ablation none` halves it.
`--max-cost-usd` bounds a run, and `-j` up to 8 shortens wall clock without raising
throughput past your rate limit.

Every run writes `results/<timestamp>/` with `aggregate-result.json` and a
self-contained `report.html`. The report is where you find out *why* a run scored low:
failed graders are expanded, and an `llm` grader shows the judge's votes and the text it
judged. `results/` is gitignored.

---

## Running in CI

`.github/workflows/evals.yaml` runs after a merge to `main`, never on a pull request,
scoped by `--tag` to the changed skills, with-plugin arm only, and `continue-on-error`.
Each of those saves money and costs coverage: a regression is reported after it lands, a
change that affects routing globally can be missed, and without the without-arm a case
that has stopped discriminating goes unnoticed. Re-check that deliberately with
`include_baseline`.

- Changing `_fixture/` widens the scope to all 15 skills, since it affects every case.
- CI needs `ANTHROPIC_API_KEY`, having no Claude Code session, and `--trust-plugin`,
  because a run with no terminal cannot answer the trust prompt. An auth failure at the
  first run exits 2, which the job checks for rather than swallowing.
- `--ablation none` is also the only mode where a `tool_used: Skill` grader is scored by
  default. This suite sets `arm: both` so routing scores in either mode, but the two
  modes still weight the baseline differently. Compare runs from one mode at a time.
- The job has a one-hour ceiling. Measured at `-j 4`, a run takes about 22 seconds, so the
  CI default of one arm at `--runs 1` fits all 100 cases in roughly 35 minutes and a
  single-skill merge finishes in a couple of minutes. A full two-arm run at `--runs 3` is
  600 runs and would need something like three and a half hours, so it does not fit: use
  the manual trigger with `scope: all-skills`, and expect to raise the ceiling.

---

## What this does not cover

- **Dart syntax.** The previous harness parsed every fenced `dart` block with
  `dart format --output=none` through a custom JavaScript assertion. Native plugin evals
  have **no custom-code graders**, so that check did not survive the migration. Thirty
  cases across eleven skills lost it. No response text was found in
  `aggregate-result.json` either, only a `tracePath` into a sandbox that is deleted unless
  `--keep-temp` is passed, so there is no clean post-hoc route back to it. The `report.html`
  does show the judged text.
- **Judge calibration.** Most graders are `llm` with no human-labelled gold set.
- **Tool execution.** The six tool-driven skills are graded only on the decisions they
  narrate. `claude plugin eval` *can* mock MCP servers, under `evals/mocks/<server>/`,
  which would let those skills be graded on the calls they actually make. Nothing here
  uses it yet.
- **Stable routing.** Whether a skill activates is nondeterministic, which is why
  routing is a `tool_used` grader rather than inferred from content.
- **Prose in a `SKILL.md`.** Deliberate. An earlier version asserted a hundred `contains`
  patterns against skill bodies, so a copy-edit failed the gate.
- **The skills' own surfaces.** `skills_lint` now covers two of the three gaps this
  section used to list: `check-relative-paths` fails a link pointing at a file that is not
  there, and the `name`/directory match is enforced. It cannot tell you a link resolves to
  the *wrong* file, and nothing checks that an `allowed-tools` name exists. `claude plugin
  validate .` was measured passing with a bogus tool name, a broken link and a
  `name`/folder mismatch all at once. Four invariants are convention alone:
  `create-project` must not declare `Bash`, `green-gate` must declare it for parsing
  `coverage/lcov.info`, `.mcp.json` must keep `--enable dart_format`, and
  `flutter-reviewer` must declare no write tools. A tool name can be correct and still
  unreachable, so a rename breaks the narration-graded skills silently.
