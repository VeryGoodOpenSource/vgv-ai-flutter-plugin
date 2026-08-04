# Skill Evals

One question: does Claude route to the skill, and does the output follow it?

```bash
npm install --no-save @anthropic-ai/claude-agent-sdk   # from the repo root, once
npx promptfoo@latest eval -c evals/promptfooconfig.yaml
```

Cases live in `evals/tests/<skill>.yaml` and run through
[promptfoo](https://www.promptfoo.dev). They call real models, so they take minutes and
consume usage. Run them locally before a PR that changes a skill. CI runs them after a
merge, scoped to the changed skills, as an advisory signal, see [Running in CI](#running-in-ci).

This file is the single source of truth. `README.md`, `CLAUDE.md` and `CONTRIBUTING.md`
carry a few lines and a link here, so eval documentation belongs in this file rather
than spread across them.

---

## Setup

- **No API key.** Both the agent under test and the `llm-rubric` judge authenticate
  through your local Claude Code session, so the suite runs on a subscription. The judge
  is pinned to the same provider in `defaultTest.options`. Left unpinned, promptfoo picks
  a grader from whatever key is in the environment, which is neither free nor
  deterministic.
- **The SDK must be in `node_modules` next to where you run promptfoo.** A `-g` install
  does not work and neither does `NODE_PATH`, because promptfoo resolves it from the
  working directory. `--no-save` keeps `package.json` out of the repo, and
  `node_modules/` is already gitignored.
- **Node `^20.20.0 || >=22.22.0`**, and `dart` on `PATH` for the `dart-parses` assertion.
- **promptfoo behavior differs across releases**, so a suite that ran yesterday can
  break on an upgrade with no change here. 0.120.0 failed to start at all. If a run dies
  before any case executes, or the two columns stop differing, pin to the last version
  you saw work and reconcile the config against the provider docs before editing a case.

---

## How it works

promptfoo drives these through its
[Claude Agent SDK provider](https://www.promptfoo.dev/docs/providers/claude-agent-sdk),
which loads this repo as a local plugin and reports which skills the model actually
invoked. Every case runs against both providers:

| Provider          | Config                                                   | Measures                     |
| ----------------- | -------------------------------------------------------- | ---------------------------- |
| `with-skill`      | `plugins` points at this repo, `skills: all`, read tools | What the plugin produces     |
| `sealed-baseline` | no `plugins`, `tools: []`                                | What the bare model produces |

**A grader that passes in both columns is measuring the model, not the skill.** That is
the number to read. `npx promptfoo@latest view` gives the side-by-side.

Measured once as a full two-column run: 79/85 in the plugin column against 3/85 sealed,
an 89-point lift, negative controls excluded because a sealed model passes
`not-skill-used` for free. The sealed column made zero tool calls on that run, so
isolation held. Two of those skills had no case changes at all and still moved, which is
what separates skill work from case work in the totals.

### Sealing the baseline takes three keys

None of these is the provider's default, and two are counter-intuitive enough that this
suite shipped leaking until a real run exposed it:

| Key                       | Why                                                                                                                                                                                                    |
| ------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `tools: []`               | `working_dir` is inside the checkout, so a baseline with read tools walks up to `../../skills`, reads `SKILL.md`, then passes rubrics on the answers. Observed via `Read`, `Grep` and `Bash`           |
| `setting_sources: []`     | **Omitting the key loads everything**, including `CLAUDE.md`, which lists every skill. No tool call is involved, so no assertion can catch it. Both columns need it, or the ablation compares contexts |
| `strict_mcp_config: true` | Without it, `--tools ""` still leaves every `mcp__*` tool in place                                                                                                                                     |

Do not reach for `custom_allowed_tools` or `append_allowed_tools` to restrict a column.
Those map to the SDK's `allowedTools`, which is an auto-approve list rather than an
availability list, and an empty array is dropped entirely, silently restoring the full
default tool set.

### Isolation is held by the config alone

`skills` is a context filter, not a sandbox. Skill files stay on disk and readable
through Read, Glob and Grep. The sealed baseline read `skills/bloc/SKILL.md` off disk on
a stock run and then passed the rubric it should have failed.

Nothing detects that automatically, and isolation has broken twice here by one of the
three keys being loosened. Treat any change to `tools`, `working_dir`, `setting_sources`
or `plugins` as invalidating every number measured before it, and re-baseline rather than
comparing across the change. **The symptom to watch for is the sealed column climbing
toward the plugin column.** That reads like the model improving and is almost always
contamination.

---

## Writing a case

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
      weight: 3
    - type: regex
      value: 'sealed class LoginEvent'
    - type: javascript
      value: file://assertions/dart-parses.js
    - type: llm-rubric
      value: >-
        Every event class name starts with the bloc's subject and ends in a past-tense
        verb, for example LoginSubmitted.
```

### Threshold and routing weight

`defaultTest.threshold` is `0.8`, so a case passes when its assertions average that or
better. The threshold is per-case, so a weak case cannot hide behind strong siblings.

**Every `skill-used` and `not-skill-used` assertion carries `weight: 3`**, so a routing
miss cannot clear the threshold on its own. Unweighted it could: a six-assertion case
whose only failure was `skill-used` averaged `0.83` and reported green, which is how a
measured bloc routing failure went unnoticed for a whole run.

Writing `n` for a case's non-routing assertions, which range from 1 to 8 here, a routing
miss scores `n / (n + 3)`, at most `0.727`. Three is the smallest weight that holds for
every case size, because a routing miss clears `0.8` whenever the weight is below
`n / 4`. The cost is asymmetric and worth knowing: on the five cases with 7 or more
content assertions, two content failures now score `0.818` to `0.900` and pass, where
unweighted they failed. Raising the weight makes that worse rather than better, since
routing then dominates the average. Restoring two-miss strictness on a large case is a
per-case fix. The one-soft-miss tolerance holds for `n >= 2`. The two `n = 1` cases fail
on a single content miss, as they did unweighted.

Nothing enforces the weight on new cases automatically.

### Assertions

| `type`                                     | Measures         | Notes                                                                                                                                               |
| ------------------------------------------ | ---------------- | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| `skill-used` / `not-skill-used`            | process          | Reads `metadata.skillCalls`, derived from `Skill` tool calls. Errored skill attempts do not satisfy it. Always `weight: 3`                          |
| `regex` / `not-regex`                      | style            | Any assertion negates with a `not-` prefix                                                                                                          |
| `contains` / `icontains` / `not-icontains` | outcome          | Case-insensitive variants for one-word answers                                                                                                      |
| `llm-rubric`                               | style            | Model-graded against a criterion                                                                                                                    |
| `javascript`                               | outcome, process | `file://assertions/*.js`, resolved against the config file's directory even from a test file, or inline reading `context.providerResponse.metadata` |

`evals/assertions/dart-parses.js` checks that every fenced ```` ```dart ```` block
parses. It runs `dart format --output=none`, which parses without resolving, because
snippets reference classes absent from the fixture and semantic analysis would fail
every case. Each block is tried three ways before counting as a failure: as-is, wrapped
in a function body for a bare statement, and wrapped as an expression for a widget tree
pasted with no trailing semicolon. The third shape was added after a run failed three
cases whose Dart was fine. It still rejects unbalanced parens, stray keywords and
truncated classes.

**Rubrics are graded blind.** The judge sees the response text and the criterion, never
the prompt. A criterion like "the response fixes the loop bound" is therefore
unanswerable and fails at random: both columns once returned byte-identical correct
output and the judge scored one `1.00` and the other `0.30`. Grade task success with a
`regex` and keep rubrics to properties visible in the text alone.

### The fixture must stay neutral

Both columns use `working_dir: ./fixture`, a bare Flutter app skeleton. An entirely
empty directory is its own confound, because with no project in sight the model asks for
the code instead of writing it and graders fail for unrelated reasons.

An earlier version of that pubspec listed `bloc`, `flutter_bloc`, `equatable`, `mocktail`
and `very_good_analysis`. The sealed column read the dependency list, inferred the
conventions the skills exist to supply, and collapsed bloc's measured lift from +10
points to +1. If anything in the fixture hints at what a skill teaches, it is handing the
baseline the answers. Keep it to what a new Flutter app ships with.

Prompts must be self-contained for the same reason. The fixture has no source in `lib/`,
so a prompt about "my AuthService" earns a careful refusal. Paste the class into the
prompt, and name pasted text as authoritative when the prompt describes state that is not
on disk, or a run will go looking for it and answer about the empty fixture instead.

### Routing is tested, not assumed

Prompts name no skill. With `skills: all` the model routes on its own, and `skill-used`
makes a routing failure legible as its own failed assertion instead of as unexplained
content failures downstream. Every skill also has one negative control asserting
`not-skill-used`, so a skill firing where it should not is caught rather than inferred.

The slash-command path cannot be measured this way. Invoking a skill as `/<name>` expands
its content into the prompt with no `Skill` tool call, so routing is only observable when
the model chooses the skill itself.

### Checklist

1. **Write the prompt as a user would send it**, with real phrasing and real ambiguity.
2. **Make it self-contained.** Paste in any class it refers to.
3. **Add `skill-used` at `weight: 3`.** The one exception is a prompt demanding a single
   token, which does not justify a Skill round-trip and would measure the harness. Three
   cases omit it and each says so in a comment. If you omit it, leave the comment.
4. **Grade mechanically where you can**, a required import or a forbidden package, and
   with `llm-rubric` where the property is structural.
5. **Only ask for what the prompt supplied.** A rubric wanting per-failure detail from a
   prompt that gave none can never pass, and a rubric wanting prose will always fail a
   prompt ending "Output Dart code only".
6. **Include the cases where the skill must say no.** Ask for the anti-pattern outright
   and grade that the response declines and offers the alternative. A skill earns its
   keep on its prohibitions.
7. **Keep the negative control's rubric to the absence of the skill's vocabulary**, and
   grade the task itself with a `regex`. A negative control whose rubric also asks "did
   it do the task" hits the blind-judge trap above.
8. **Write criteria a stranger could apply** from the response text alone, naming what
   satisfies them and what does not.
9. **Check it beats the baseline.** An assertion that passes in the sealed column too is
   measuring Claude, not your skill. One case was dropped for scoring `1.00` in both.

---

## Running the suite

```bash
P="npx promptfoo@latest"
$P eval -c evals/promptfooconfig.yaml                            # all 100, both columns
$P eval -c evals/promptfooconfig.yaml --filter-pattern bloc      # one skill
$P eval -c evals/promptfooconfig.yaml --filter-providers with-skill
$P eval -c evals/promptfooconfig.yaml --repeat 3 --no-cache      # is a red case real?
$P eval -c evals/promptfooconfig.yaml --retry-errors             # re-run 529s only
$P view                                                          # the side-by-side
```

**Read the per-column split, not promptfoo's total.** The sealed column is meant to fail,
so roughly a third of the 200 results failing is the healthy shape. Write the run to the
gitignored `evals/.runs/`, then split it:

```bash
$P eval -c evals/promptfooconfig.yaml --no-table -o evals/.runs/latest.json
node -e 'const r=require("./evals/.runs/latest.json"),c={};for(const x of r.results.results){const l=x.provider.label;c[l]??={n:0,pass:0};c[l].n++;c[l].pass+=x.success?1:0}console.table(c)'
```

`node evals/ci-summary.js evals/.runs/latest.json` renders the same run as the per-skill
table CI posts. It buckets errored results separately, so a skill whose cases errored
reads as thin coverage rather than as failures.

**One run is not a measurement.** These are non-deterministic and they are not a merge
gate. Treat a single red case as a prompt to look, never as proof of a regression:

- `--no-cache` is required for fresh generations, since promptfoo caches by default.
- `--repeat 3` before editing anything. Unedited cases have been measured moving between
  runs, one across the pass/fail line, and cases drifting between 2/3 and 3/3 are this
  suite's noise floor. Two skills were nearly "fixed" off single red reps that a repeat
  run showed were noise.
- A `529 Overloaded` scores 0 with no failing assertion, indistinguishable from a content
  failure unless you check `res.error`. One full run hit 14 of them, and a long local run
  hit 19 clustered in its final 12% as the session throttled. Follow up with
  `--retry-errors` before believing a failure count.
- Variance in the plugin column is mostly routing rather than content.

Budget roughly $0.10 to $0.20 and 10 to 30 seconds per case per provider, so a full
two-column run of 100 cases lands near $20 to $40 of equivalent usage and well over half
an hour. A 300-case `--repeat 3` run took 4h32m locally. Use `--filter-pattern` while
iterating. A full run is a release-time check, not an edit-loop one.

---

## Running in CI

`.github/workflows/evals.yaml` runs these **after a merge to `main`**, never on a pull
request. Three choices keep the bill down, and each costs something:

| Choice                   | Saves                                                    | Costs                                                            |
| ------------------------ | -------------------------------------------------------- | ---------------------------------------------------------------- |
| Post-merge, not per-PR   | A PR is pushed to many times, `main` is merged into once | A regression is reported after it lands                          |
| Only the changed skills  | One skill is 6 or 7 cases out of 100                     | A change affecting routing globally can be missed                |
| `with-skill` column only | Half of every run                                        | No ablation, so it cannot tell you a case stopped discriminating |

Dropping the sealed column is the safe half of that. The baseline exists to prove a case
*discriminates*, which you answer once when writing the case. Regression detection does
not need it. Re-check it deliberately with the `include_baseline` input.

A change to `promptfooconfig.yaml`, `assertions/` or `fixture/` widens the scope to all
15 skills, since any of them can affect every case.

Cost is bounded rather than estimated. `max_budget_usd` is enforced per case, so the
ceiling is `cases × columns × max_budget_usd`: about **$3.50** for a one-skill merge at
the current `0.5`, and **$100** for a full two-column run. Typical spend is far below
that, but the ceiling is the number for a budget alarm, and a case that hits it errors
rather than overspending.

Two differences from the local path:

- **It needs `ANTHROPIC_API_KEY`.** Locally both providers set `apiKeyRequired: false`
  and use the Claude Code session, while CI has none. The workflow runs a one-case smoke
  test first so an auth problem fails in seconds rather than after a full matrix.
- **It is `continue-on-error`**, deliberately, for the variance reasons above. Confirm
  anything red locally with `--repeat 3`.

The job has a one-hour ceiling. 100 cases in one column fits. A `--repeat 3` dispatch
does not, and will be cancelled without writing an artifact. Shard by skill across
parallel jobs if that mode is wanted. For a full run before a release, use the manual
trigger with `scope: all-skills`.

---

## What these evals do not cover

| Not covered                   | Why                                                                                                                                                                                                                                                                                        |
| ----------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Judge calibration**         | Most assertions are `llm-rubric` with no human-labelled gold set and no measured agreement. Strong judges reach roughly 80% agreement with humans, and raw agreement can read 90% while a judge does nothing meaningful. Rubric verdicts are unverified until someone hand-labels a sample |
| **Tool execution**            | No MCP servers are configured, so the six skills whose real job is calling tools or mutating files, `create-project`, `green-gate`, `license-compliance`, `ui-package`, `dart-flutter-sdk-upgrade` and `very-good-analysis-upgrade`, are graded only on the decisions they narrate         |
| **Whether the code compiles** | `dart-parses` proves syntax only. Snippets reference classes absent from the fixture                                                                                                                                                                                                       |
| **Judge independence**        | Generator and rubric grader are the same model family and may share blind spots                                                                                                                                                                                                            |
| **Stable routing**            | Whether a skill activates is itself nondeterministic. One case routed 3 of 3 on one pass and failed to route on the next, taking every downstream assertion with it. This is why `skill-used` is its own assertion                                                                         |
| **Prose in a `SKILL.md`**     | Deliberate. An earlier version asserted about a hundred `contains` patterns against skill bodies, so a copy-edit failed the gate while teaching the same thing                                                                                                                             |
| **The skills' own surfaces**  | Nothing verifies that a name in `allowed-tools` still exists, that a markdown link to a reference resolves, or that `name` agrees with the directory. See below                                                                                                                            |

`claude plugin validate .` does not cover the surfaces either. It was measured passing
with a bogus tool name, a broken reference link, and a `name`/folder mismatch all in
place at once. Four invariants are held by convention alone:

- `create-project` must not declare `Bash`, because scaffolding goes through the Very
  Good CLI MCP server and `block-cli-workarounds.sh` blocks the Bash path
- `green-gate` must declare `Bash`, because the coverage gate parses
  `coverage/lcov.info` and no MCP tool reads it
- `.mcp.json` must keep `--enable dart_format`, because the Dart MCP server's `cli`
  feature category is off by default
- the `flutter-reviewer` agent must declare no `Edit`, `Write` or `NotebookEdit`, because
  `tools` cannot scope Bash by command

The failure mode to watch for is a Claude Code or MCP release renaming a tool. A skill
still naming the old one breaks silently, and the six narration-graded skills are the
weak spot: they describe the tool they would call, so a case asserting that description
keeps passing after the tool ceases to exist. `green-gate` shipped exactly that bug,
naming `mcp__dart__dart_format` while `.mcp.json` started the server without
`--enable dart_format`. Note the shape of it. The tool existed the whole time, in a
feature category the server disables by default, so checking that a tool exists
somewhere is not the same as checking that this config exposes it.

---

## When to update what

| You changed                | Do this                                                       |
| -------------------------- | ------------------------------------------------------------- |
| Added a skill              | Add `evals/tests/<skill>.yaml` and register it under `tests:` |
| What a skill teaches       | Run its cases and update any that asserted the old behavior   |
| A skill's reference layout | Update every markdown link to the moved file by hand          |
| A skill's `allowed-tools`  | Confirm by hand that every name still exists                  |
| `promptfooconfig.yaml`     | Re-baseline. Earlier numbers are not comparable across it     |
