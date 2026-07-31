# Skill Evals

One question: does Claude route to the skill, and does the output follow it?

```bash
npx promptfoo@latest eval -c evals/promptfooconfig.yaml
```

Cases live in `evals/tests/*.yaml` and run through
[promptfoo](https://www.promptfoo.dev). They call real models, so they take minutes
and consume usage. Nothing here runs in CI. Run them locally before a PR that
changes a skill.

This file is the single source of truth. `README.md`, `CLAUDE.md` and
`CONTRIBUTING.md` carry a few lines and a link here, so eval documentation belongs in
this file rather than spread across them.

---

## How it works

promptfoo drives these through its
[Claude Agent SDK provider](https://www.promptfoo.dev/docs/providers/claude-agent-sdk),
which loads this repo as a local plugin and reports which skills the model actually
invoked. Everything lives in `evals/promptfooconfig.yaml` plus one YAML file of cases
per skill under `evals/tests/`.

**No API key.** Both the agent under test and the `llm-rubric` judge run through the
Claude Agent SDK, which authenticates with your local Claude Code session, so the
whole suite runs on a subscription. The judge is pinned to the same provider in
`defaultTest.options`; left unpinned, promptfoo picks a grader from whatever key
happens to be in the environment, which is neither free nor deterministic.

Two prerequisites:

```bash
npm install --no-save @anthropic-ai/claude-agent-sdk   # from the repo root
npx promptfoo@latest eval -c evals/promptfooconfig.yaml
```

- **The SDK must live in `node_modules` next to where you run promptfoo.** A `-g`
  install does not work and neither does `NODE_PATH` — promptfoo resolves the SDK
  from the working directory. `--no-save` keeps `package.json` and a lockfile out of
  this repo; `node_modules/` is already gitignored.
- **Node `^20.20.0 || >=22.22.0`**. `dart` also has to be on PATH for the
  `dart_parses` assertion.

Behavior differs across promptfoo releases, so a suite that ran yesterday can break on
an upgrade with no change here. 0.120.0 failed to start at all. If a run dies before any
case executes, or the two columns stop differing, pin to the last version you saw work
and reconcile the config against the provider docs before editing a case.

### The two columns are the ablation

Every case runs against both providers:

| Provider | Config | Measures |
| -------- | ------ | -------- |
| `with-skill` | `plugins` points at this repo, `skills: all`, read tools | What the plugin produces |
| `sealed-baseline` | no `plugins`, `tools: []` | What the bare model produces |

### Sealing the baseline takes three keys

Nothing here is the provider's default, and two of them are counter-intuitive
enough that this suite shipped leaking until a real run exposed it:

| Key | Why |
| --- | --- |
| `tools: []` | `working_dir` is inside the checkout, so a baseline with read tools walks up to `../../skills` and reads `SKILL.md` — then passes rubrics on the answers. Observed via `Read`, `Grep` and `Bash`. This emits `--tools ""`, removing all built-ins |
| `setting_sources: []` | **Omitting the key loads everything**, including `CLAUDE.md`, which lists every skill. No tool call is involved, so no assertion can catch it |
| `strict_mcp_config: true` | Without it, `--tools ""` still leaves every `mcp__*` tool in place |

Do not reach for `custom_allowed_tools` or `append_allowed_tools` to restrict a
column. Those map to the SDK's `allowedTools`, which is an auto-approve list, not
an availability list — the SDK's own docs say to use `tools` for that, and an empty
array is dropped entirely, silently restoring the full default tool set.

Both columns carry `setting_sources: []`. If only one does, the ablation compares
contexts rather than the plugin. Plugins load through `--plugin-dir`, so `skills:
all` still works with settings disabled.

**A grader that passes in both columns is measuring the model, not the skill.** That
is the number to read. Use `npx promptfoo@latest view` for the side-by-side.

### Case format

`evals/tests/<skill>.yaml` is a list of promptfoo tests:

```yaml
- description: bloc-writes-sealed-events-and-states
  vars:
    prompt: >-
      Write a LoginBloc for email and password authentication with submit and logout
      events, and success and failure states. Output Dart code only.
  assert:
    - type: skill-used
      value: 'vgv-ai-flutter-plugin:bloc'
    - type: regex
      value: 'sealed class LoginEvent'
    - type: not-regex
      value: 'package:mockito'
    - type: javascript
      value: file://assertions/dart-parses.js
    - type: llm-rubric
      value: >-
        Every event class name starts with the bloc's subject and ends in a past-tense
        verb, for example LoginSubmitted.
```

`defaultTest.threshold` in the config is `0.8`, so each case passes when its
assertions average that or better. The threshold is per-case, so a weak case cannot
hide behind strong siblings.

### Assertions

| `type` | Measures | Notes |
| ------ | -------- | ----- |
| `skill-used` / `not-skill-used` | process | Reads `metadata.skillCalls`, which promptfoo derives from `Skill` tool calls. Errored skill attempts do not satisfy it |
| `regex` / `not-regex` | style | Any assertion negates with a `not-` prefix |
| `contains` / `icontains` / `not-icontains` | outcome | Case-insensitive variants for one-word answers |
| `llm-rubric` | style | Model-graded against a criterion |
| `javascript` | outcome, process | `file://assertions/*.js` — promptfoo resolves `file://` against the config file's directory, even from a test file — or inline reading `context.providerResponse.metadata` |

One custom assertion lives in `evals/assertions/`:

- **`dart-parses.js`** — every fenced ```` ```dart ```` block parses. Runs
  `dart format --output=none`, which parses without resolving, because snippets
  reference classes absent from the fixture and semantic analysis would fail every
  case. A block is tried three ways before it counts as a failure: as-is, wrapped in a
  function body for a statement like `ArticleRoute(id).go(context);`, and wrapped as an
  expression for a widget tree pasted with no trailing semicolon. The third shape was
  added after a measured run failed three cases whose Dart was fine — a bare
  `AppButton(label: 'Save')` is neither a compilation unit nor a statement. Verified
  that it still rejects unbalanced parens, stray keywords and truncated classes.

**Rubrics are graded blind.** The judge sees the response text and the criterion, never
the prompt. So a criterion like "the response fixes the loop bound" is unanswerable, and
it fails at random: both columns once returned byte-identical correct output for
`layered-architecture-stays-out-of-single-file-work` and the judge scored one 1.00 and
the other 0.30. Grade task success with a `regex` and keep the rubric to properties
visible in the text alone.

### Isolation is held by the config alone

`skills` is a context filter, not a sandbox. Skill files stay on disk and readable
through Read, Glob and Grep, and `working_dir` points inside this checkout. A run that
never invoked a skill yet opened `SKILL.md` had the answers, so its score measures
nothing. That is not hypothetical: the sealed baseline read `skills/bloc/SKILL.md` off
disk on a stock run and then passed the rubric it should have failed.

Nothing detects that automatically. The three keys in the table above are the only
thing holding isolation, and it has broken twice here by one of them being loosened. So
treat any change to `tools`, `working_dir`, `setting_sources` or `plugins` as
invalidating every number measured before it, and re-baseline rather than comparing
across the change.

The symptom to watch for is the sealed column climbing toward the plugin column. That
reads like the model improving and is almost always contamination.

### Skill routing is tested, not assumed

Prompts name no skill. With `skills: all` the model routes on its own, and
`skill-used` makes a routing failure visible as its own failed assertion instead of as
unexplained content failures downstream. Negative controls invert it: every skill has
one case asserting `not-skill-used`, so a skill firing where it should not is caught
rather than inferred from the prose.

The slash-command path cannot be measured this way: invoking a skill as `/<name>`
expands its content into the prompt with no `Skill` tool call, so routing is only
observable when the model chooses the skill itself.

### The fixture must stay neutral

Both providers use `working_dir: ./fixture`, a bare Flutter app skeleton. An entirely
empty directory is its own confound — with no project in sight the model asks for the
code instead of writing it, and graders fail for reasons unrelated to the skill.

An earlier version of that pubspec listed `bloc`, `flutter_bloc`, `equatable`,
`mocktail` and `very_good_analysis`. The sealed column read the dependency list and
inferred the conventions the skills exist to supply, collapsing bloc's measured lift
from +10 points to +1. If anything in the fixture hints at what a skill teaches, it is
handing the baseline the answers. Keep it to what a new Flutter app ships with.

Prompts must be self-contained for the same reason: the fixture has no source in
`lib/`, so a prompt about "my AuthService" earns a careful refusal. Paste the class
into the prompt rather than adding source to the fixture.

### Running the suite

```bash
P="npx promptfoo@latest"
$P eval -c evals/promptfooconfig.yaml                          # all 100, both columns
$P eval -c evals/promptfooconfig.yaml --filter-pattern bloc    # one skill
$P eval -c evals/promptfooconfig.yaml --repeat 2 --no-cache    # is a red case real?
$P eval -c evals/promptfooconfig.yaml --retry-errors           # re-run 529s only
$P view                                                        # the side-by-side
```

**Read the per-column split, not promptfoo's total.** The sealed column is meant to fail,
so roughly a third of the 200 results failing is the healthy shape, not a regression. Write
the run to the gitignored `evals/.runs/`, then split it:

```bash
$P eval -c evals/promptfooconfig.yaml --no-table -o evals/.runs/latest.json
node -e 'const r=require("./evals/.runs/latest.json"),c={};for(const x of r.results.results){const l=x.provider.label;c[l]??={n:0,pass:0};c[l].n++;c[l].pass+=x.success?1:0}console.table(c)'
```

**Only 33 of the 100 cases have ever been run.** The five original skills have a measured
baseline; the ten added later do not, so treat their first run as calibration rather than
as a verdict on those skills.

Measured baseline, first full run of the original five skills, negative controls excluded
because a sealed model passes `not-skill-used` for free:

| Skill | `with-skill` | `sealed` |
| ----- | ------------ | -------- |
| navigation | 6/6 | 0/6 |
| layered-architecture | 6/6 | 0/6 |
| create-project | 5/6 | 0/6 |
| bloc | 5/5 | 1/5 |
| testing | 4/5 | 0/5 |
| **total** | **26/28** | **1/28** |

That run took 12m37s and 66,904 tokens for 66 results, and the sealed column made zero
tool calls.

The plugin column is not reliably perfect, and the variance is routing rather than content.
Both misses in that run cascaded from `Actual skills: (none)`, and one of them passed 3/3 on
a `--repeat`. So a red case there is worth a `--repeat 3` before it is worth an edit. If the
sealed column climbs toward the other one, isolation has broken rather than the model having
improved — that has already happened twice here.

Two things about the numbers. promptfoo caches by default, so `--no-cache` is needed
for fresh generations, and `--repeat N` shows the noise floor. And a `529 Overloaded`
scores 0 with no failing assertion, which is indistinguishable from a content failure
unless you check `res.error` — one full run hit 14 of them, so always follow up with
`--retry-errors` before believing a failure count.

Expect roughly $0.10–0.20 and 10–30 seconds per case per provider, so a full run of 100
cases across both columns lands around $20–40 of equivalent usage and well over half an
hour. Use `--filter-pattern <skill>` while iterating; a full run is a release-time check,
not an edit-loop one.

These are not a merge gate, and nothing here runs in CI yet — run them locally before
a PR that changes a skill. They are non-deterministic and a single rubric verdict can
move a case, so treat one red case as a prompt to look rather than proof of a
regression. `--repeat 2` is the cheapest way to tell a real failure from noise.

### What these evals do not cover

| Not covered | Why |
| ----------- | --- |
| **Judge calibration** | 164 assertions are `llm-rubric` with no human-labelled gold set and no measured agreement. Strong judges reach roughly 80% agreement with humans, and raw agreement can read 90% while a judge does nothing meaningful. Until someone hand-labels a sample, rubric verdicts are unverified — and `llm-rubric` does not calibrate itself |
| **Tool execution** | No MCP servers are configured, so the six skills whose real job is calling tools or mutating files — `create-project`, `green-gate`, `license-compliance`, `ui-package`, `dart-flutter-sdk-upgrade`, `very-good-analysis-upgrade` — are graded only on the decisions they narrate. Their numbers are weaker evidence than the other nine skills' by construction |
| **Whether the code compiles** | `dart_parses` proves syntax only. Snippets reference classes absent from the fixture |
| **Judge independence** | Generator and rubric grader are the same model family and may share blind spots |
| **Unmeasured cases** | All 15 skills have cases, but 67 of the 100 have never been run. Only the original five skills have a measured baseline |
| **Stable routing** | Whether a skill activates is itself nondeterministic. `testing-declines-mockito` routed 3 of 3 on one pass and failed to route on the next, taking every downstream assertion with it. This is why `skill-used` is its own assertion rather than inferred from content |
| **Prose in a `SKILL.md`** | Deliberate. An earlier version asserted about a hundred `contains` patterns against skill bodies, so a copy-edit failed the gate while teaching exactly the same thing |
| **The skills' own surfaces** | Nothing verifies that a name in `allowed-tools` still exists, that a markdown link to a reference file resolves, or that `name` agrees with the directory. See below |

Nothing checks the surfaces either. `claude plugin validate .` in CI does not cover
them — it was measured passing with a bogus tool name, a broken reference link, and a
`name`/folder mismatch all in place at once. So three frontmatter invariants are held
by convention alone:

- `create-project` must not declare `Bash` — scaffolding goes through the Very Good
  CLI MCP server, and `block-cli-workarounds.sh` blocks the Bash path
- `green-gate` must declare `Bash` — the Dart MCP server exposes no formatter, so the
  format gate runs `dart format` through it
- the `flutter-reviewer` agent must declare no `Edit`, `Write` or `NotebookEdit` —
  `tools` cannot scope Bash by command, so a read-only agent has to omit write tools
  entirely

The failure mode to watch for is a Claude Code or MCP release renaming a tool. A skill still
naming the old one breaks silently. Cases catch this only where the skill's output changes as
a result, so the six narration-graded skills are the weak spot: they describe the tool they
would call, and a case asserting that description keeps passing after the tool ceases to
exist. `green-gate` shipped exactly that bug, naming a `mcp__dart__dart_format` tool the Dart
MCP server never exposed.

### Adding a case

1. **Write the prompt as a user would send it.** Real phrasing, real ambiguity.
2. **Make it self-contained.** Paste in any class the prompt refers to.
3. **Add `skill-used`** so a routing failure is legible on its own. The one exception
   is a prompt demanding a single token ("Answer with only the template name"), which
   does not justify a Skill round-trip and measures the harness instead — three cases
   omit it for that reason and each says so in a comment. If you omit it, leave the
   comment.
4. **Grade mechanically where you can** — a required import, a `sealed class`, a
   forbidden package — and with `llm-rubric` where the property is structural.
5. **Include the cases where the skill must say no.** Ask for the anti-pattern
   outright and grade that the response declines and offers the alternative. A skill
   earns its keep on its prohibitions.
6. **Keep one negative control per skill**, asserting `not-skill-used`. Grade only the
   *absence* of the skill's vocabulary in the rubric, and the task itself with a
   `regex`. A negative control whose rubric also asks "did it do the task" is the
   blind-judge trap above.
7. **Write rubric criteria a stranger could apply**, using only the response text.
   Name what satisfies it and what does not.
8. **Check it beats the baseline.** If the assertion passes in the sealed column too,
   it is measuring Claude, not your skill. Strengthen it or drop it. One case was
   dropped for exactly this after scoring 1.00 in both columns.
9. **Do not ask for what the prompt forbade.** A rubric wanting prose about
   `build_runner` will always fail a prompt ending "Output Dart code only".

---

## When to update what

| You changed | Do this |
| ----------- | ------- |
| Added a skill | Add `evals/tests/<skill>.yaml` and register it under `tests:` |
| What a skill teaches | Run its cases and update any that asserted the old behavior |
| A skill's reference layout | Update every markdown link to the moved file by hand |
| A skill's `allowed-tools` | Confirm by hand that every name still exists |
