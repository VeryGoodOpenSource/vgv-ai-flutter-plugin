# Skill Evals

One question: does Claude route to the skill, and does the output follow it?

```bash
npm install --no-save @anthropic-ai/claude-agent-sdk   # from the repo root, once
npx promptfoo@latest eval -c evals/promptfooconfig.yaml
```

Cases live in `evals/tests/<skill>.yaml` and run through
[promptfoo](https://www.promptfoo.dev). They call real models, so run them locally before
a PR that changes a skill. CI runs them after a merge as an advisory signal, see
[Running in CI](#running-in-ci).

This file is the single source of truth. `README.md`, `CLAUDE.md` and `CONTRIBUTING.md`
link here rather than repeating any of it.

---

## Setup

- **No API key.** The agent under test and the `llm-rubric` judge both authenticate
  through your local Claude Code session. The judge is pinned to that provider in
  `defaultTest.options`. Unpinned, promptfoo grades with whatever key is in the
  environment.
- **The SDK must be in `node_modules` next to where you run promptfoo.** A `-g` install
  does not work and neither does `NODE_PATH`.
- **Node `^20.20.0 || >=22.22.0`**, and `dart` on `PATH` for `dart-parses`.
- **Pin promptfoo if a run breaks with no change here.** Behavior differs across
  releases and 0.120.0 failed to start at all.

---

## How it works

promptfoo drives these through its
[Claude Agent SDK provider](https://www.promptfoo.dev/docs/providers/claude-agent-sdk),
which loads this repo as a local plugin and reports which skills the model invoked. Every
case runs against both providers:

| Provider          | Config                                                   | Measures                     |
| ----------------- | -------------------------------------------------------- | ---------------------------- |
| `with-skill`      | `plugins` points at this repo, `skills: all`, read tools | What the plugin produces     |
| `sealed-baseline` | no `plugins`, `tools: []`                                | What the bare model produces |

**A grader that passes in both columns is measuring the model, not the skill.** Exclude
negative controls when comparing columns, since a sealed model passes `not-skill-used`
for free.

### Sealing the baseline takes three keys

None is the provider's default, and this suite shipped leaking until a run exposed it:

| Key                       | Why                                                                                                          |
| ------------------------- | ------------------------------------------------------------------------------------------------------------ |
| `tools: []`               | `working_dir` is inside the checkout, so read tools let the baseline walk to `../../skills` and read answers |
| `setting_sources: []`     | Omitting it loads everything, including the `CLAUDE.md` that lists every skill. Both columns need it         |
| `strict_mcp_config: true` | Without it, `--tools ""` still leaves every `mcp__*` tool in place                                           |

Do not restrict a column with `custom_allowed_tools` or `append_allowed_tools`. Those map
to `allowedTools`, an auto-approve list rather than an availability list, and an empty
array is dropped entirely.

### Isolation is held by the config alone

`skills` is a context filter, not a sandbox. Skill files stay on disk and readable, and
the sealed baseline has read `skills/bloc/SKILL.md` off disk and then passed a rubric it
should have failed.

Treat any change to `tools`, `working_dir`, `setting_sources` or `plugins` as invalidating
every number measured before it. Two checks: the sealed column should make **zero tool
calls**, and it should not be climbing toward the plugin column. Climbing reads like the
model improving and is almost always contamination.

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

A case passes at `defaultTest.threshold`, `0.8`, averaged across its assertions.

**Routing carries `weight: 3`, so a routing miss alone sinks the case.** Unweighted it did
not: a six-assertion case failing only `skill-used` averaged `0.83` and reported green.
Three is the minimum that works across every case size here. It buys that by letting two
content misses pass on the five largest cases, and raising it further makes that worse
rather than better. Nothing applies the weight to new cases for you.

### Assertions

| `type`                                     | Measures         | Notes                                                                                         |
| ------------------------------------------ | ---------------- | --------------------------------------------------------------------------------------------- |
| `skill-used` / `not-skill-used`            | process          | Reads `metadata.skillCalls`. An errored skill attempt does not satisfy it. Always `weight: 3` |
| `regex` / `not-regex`                      | style            | Any assertion negates with a `not-` prefix                                                    |
| `contains` / `icontains` / `not-icontains` | outcome          | Case-insensitive variants for one-word answers                                                |
| `llm-rubric`                               | style            | Model-graded against a criterion                                                              |
| `javascript`                               | outcome, process | `file://assertions/*.js`, resolved against the config's directory even from a test file       |

`dart-parses.js` checks that every fenced ```` ```dart ```` block parses. It runs
`dart format --output=none` so nothing has to resolve, and tries each block three ways
before failing it: as-is, as a statement, and as a bare expression. Keep all three, the
last was added after a run failed three cases whose Dart was fine.

**Rubrics are graded blind**, on the response text and the criterion with no prompt. So
"the response fixes the loop bound" is unanswerable and scores at random: identical
output once scored `1.00` in one column and `0.30` in the other. Grade task success with
a `regex` and keep rubrics to properties visible in the text alone.

### The fixture must stay neutral

Both columns use `working_dir: ./fixture`, a bare Flutter app skeleton. It cannot be
empty, or the model asks for code instead of writing it. It also cannot hint at what a
skill teaches: an earlier pubspec listed `bloc`, `flutter_bloc`, `equatable` and
`mocktail`, and the sealed column inferred the conventions from the dependency list,
collapsing bloc's measured lift from +10 points to +1. Keep it to what a new Flutter app
ships with.

Prompts must be self-contained for the same reason. Paste in any class the prompt refers
to, and name pasted text as authoritative when it describes state not on disk, or a run
will go looking and answer about the empty fixture instead.

### Routing is tested, not assumed

Prompts name no skill. With `skills: all` the model routes on its own, and `skill-used`
makes a routing failure legible instead of showing up as unexplained content failures.
Every skill also has one negative control asserting `not-skill-used`.

The slash-command path cannot be measured this way. `/<name>` expands the skill into the
prompt with no `Skill` tool call, so routing is only observable when the model chooses.

### Checklist

1. **Write the prompt as a user would send it**, with real phrasing and real ambiguity.
2. **Make it self-contained.** Paste in any class it refers to.
3. **Add `skill-used` at `weight: 3`.** Three cases omit it because they demand a single
   token, and each says so in a comment. If you omit it, leave the comment.
4. **Grade mechanically where you can**, and with `llm-rubric` where the property is
   structural.
5. **Only ask for what the prompt supplied.** A rubric wanting per-failure detail from a
   prompt that gave none can never pass.
6. **Include the cases where the skill must say no.** A skill earns its keep on its
   prohibitions.
7. **Keep the negative control's rubric to the absence of the skill's vocabulary**, and
   grade the task with a `regex`. Asking a blind judge "did it do the task" is the trap
   above.
8. **Write criteria a stranger could apply** from the response text alone.
9. **Check it beats the baseline.** An assertion that also passes sealed is measuring
   Claude. One case was dropped for scoring `1.00` in both.

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
so about a third of the 200 results failing is the healthy shape. Write runs to the
gitignored `evals/.runs/`, then split:

```bash
$P eval -c evals/promptfooconfig.yaml --no-table -o evals/.runs/latest.json
node -e 'const r=require("./evals/.runs/latest.json"),c={};for(const x of r.results.results){const l=x.provider.label;c[l]??={n:0,pass:0};c[l].n++;c[l].pass+=x.success?1:0}console.table(c)'
```

`node evals/ci-summary.js evals/.runs/latest.json` renders the per-skill table CI posts,
bucketing errored results separately so an errored skill reads as thin coverage rather
than failure.

**One run is not a measurement**, and these are not a merge gate.

- `--no-cache` for fresh generations. promptfoo caches by default.
- `--repeat 3` before editing anything. Unedited cases move between runs, and cases
  drifting between 2/3 and 3/3 are this suite's noise floor. Two skills were nearly
  "fixed" off single red reps that turned out to be noise.
- A `529 Overloaded` scores 0 with no failing assertion, so it is indistinguishable from
  a content failure unless you check `res.error`. Follow up with `--retry-errors`.
- Variance in the plugin column is mostly routing rather than content.

Budget roughly $0.10 to $0.20 and 10 to 30 seconds per case per provider. A full
two-column run is a release-time check, not an edit-loop one, so use `--filter-pattern`
while iterating.

---

## Running in CI

`.github/workflows/evals.yaml` runs these **after a merge to `main`**, never on a pull
request. Three choices keep the bill down, and each costs something:

| Choice                   | Saves                                                    | Costs                                                            |
| ------------------------ | -------------------------------------------------------- | ---------------------------------------------------------------- |
| Post-merge, not per-PR   | A PR is pushed to many times, `main` is merged into once | A regression is reported after it lands                          |
| Only the changed skills  | One skill is 6 or 7 cases out of 100                     | A change affecting routing globally can be missed                |
| `with-skill` column only | Half of every run                                        | No ablation, so it cannot tell you a case stopped discriminating |

Dropping the sealed column is the safe half. The baseline proves a case *discriminates*,
which you answer once when writing it. Re-check deliberately with `include_baseline`.

Changing `promptfooconfig.yaml`, `assertions/` or `fixture/` widens the scope to all 15
skills, since any of them affects every case.

`max_budget_usd` is enforced per case, so cost is bounded rather than estimated:
`cases × columns × max_budget_usd`, about **$3.50** for a one-skill merge and **$100**
for a full two-column run. A case that hits the ceiling errors rather than overspending.

Two differences from local:

- **It needs `ANTHROPIC_API_KEY`**, since there is no Claude Code session. A one-case
  smoke test runs first so auth fails in seconds rather than after a full matrix.
- **It is `continue-on-error`**, deliberately, for the variance reasons above.

The job has a one-hour ceiling. 100 cases in one column fits, `--repeat 3` does not and
will be cancelled without an artifact. Shard by skill if you want that mode. For a full
run before a release, use the manual trigger with `scope: all-skills`.

---

## What these evals do not cover

| Not covered                   | Why                                                                                                                                          |
| ----------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- |
| **Judge calibration**         | Most assertions are `llm-rubric` with no human-labelled gold set. Raw agreement can read 90% while a judge does nothing meaningful           |
| **Tool execution**            | No MCP servers are configured, so the six skills whose job is calling tools are graded only on the decisions they narrate                    |
| **Whether the code compiles** | `dart-parses` proves syntax only                                                                                                             |
| **Judge independence**        | Generator and grader are the same model family and may share blind spots                                                                     |
| **Stable routing**            | Whether a skill activates is nondeterministic. One case routed 3 of 3 on one pass and not at all on the next, taking every assertion with it |
| **Prose in a `SKILL.md`**     | Deliberate. An earlier version asserted a hundred `contains` patterns against skill bodies, so a copy-edit failed the gate                   |
| **The skills' own surfaces**  | Nothing verifies that an `allowed-tools` name exists, that a reference link resolves, or that `name` matches the directory                   |

`claude plugin validate .` does not cover the surfaces either. It was measured passing
with a bogus tool name, a broken reference link and a `name`/folder mismatch all at once.
Four invariants are held by convention alone:

- `create-project` must not declare `Bash`, since `block-cli-workarounds.sh` blocks that
  path and scaffolding goes through the Very Good CLI MCP server
- `green-gate` must declare `Bash`, since the coverage gate parses `coverage/lcov.info`
  and no MCP tool reads it
- `.mcp.json` must keep `--enable dart_format`, since the Dart MCP server's `cli` feature
  category is off by default
- the `flutter-reviewer` agent must declare no `Edit`, `Write` or `NotebookEdit`, since
  `tools` cannot scope Bash by command

The failure mode to watch for is a release renaming a tool. The narration-graded skills
describe the tool they would call, so a case asserting that description keeps passing
after the tool stops being reachable. `green-gate` shipped that bug, naming
`mcp__dart__dart_format` while `.mcp.json` started the server without
`--enable dart_format`. A name can be correct and still unreachable, so checking that a
tool exists is not checking that this config exposes it.

---

## When to update what

| You changed                | Do this                                                       |
| -------------------------- | ------------------------------------------------------------- |
| Added a skill              | Add `evals/tests/<skill>.yaml` and register it under `tests:` |
| What a skill teaches       | Run its cases and update any that asserted the old behavior   |
| A skill's reference layout | Update every markdown link to the moved file by hand          |
| A skill's `allowed-tools`  | Confirm by hand that every name still exists                  |
| `promptfooconfig.yaml`     | Re-baseline. Earlier numbers are not comparable across it     |
