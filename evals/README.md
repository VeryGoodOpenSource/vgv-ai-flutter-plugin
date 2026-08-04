# Skill Evals

Does Claude route to the skill, and does the output follow it? Cases live in
`evals/tests/<skill>.yaml` and run through [promptfoo](https://www.promptfoo.dev)
against real models.

```bash
npm install --no-save @anthropic-ai/claude-agent-sdk   # from the repo root, once
npx promptfoo@latest eval -c evals/promptfooconfig.yaml
```

- The SDK must sit in `node_modules` next to where you run promptfoo. `-g` and
  `NODE_PATH` do not work.
- Node `^20.20.0 || >=22.22.0`, and `dart` on `PATH` for `dart-parses`.
- No API key. Agent and judge both use your Claude Code session. The judge is pinned in
  `defaultTest.options`, and unpinned it grades with whatever key is in the environment.
- Pin promptfoo if a run breaks with no change here. 0.120.0 failed to start at all.

---

## The two columns

| Provider          | Config                                                   | Measures                     |
| ----------------- | -------------------------------------------------------- | ---------------------------- |
| `with-skill`      | `plugins` points at this repo, `skills: all`, read tools | What the plugin produces     |
| `sealed-baseline` | no `plugins`, `tools: []`                                | What the bare model produces |

A grader that passes in both is measuring the model, not the skill. Exclude negative
controls when comparing, since a sealed model passes `not-skill-used` for free.

**Sealing the baseline takes three keys, and this suite shipped leaking until a run
exposed it.** None is the provider's default:

| Key                       | Why                                                                                                          |
| ------------------------- | ------------------------------------------------------------------------------------------------------------ |
| `tools: []`               | `working_dir` is inside the checkout, so read tools let the baseline walk to `../../skills` and read answers |
| `setting_sources: []`     | Omitting it loads everything, including the `CLAUDE.md` that lists every skill. Both columns need it         |
| `strict_mcp_config: true` | Without it, `--tools ""` still leaves every `mcp__*` tool in place                                           |

Do not restrict a column with `custom_allowed_tools` or `append_allowed_tools`. Those map
to `allowedTools`, an auto-approve list rather than an availability list, and an empty
array is dropped entirely.

`skills` is a context filter, not a sandbox: skill files stay readable on disk, and the
sealed baseline has read `skills/bloc/SKILL.md` and then passed a rubric it should have
failed. Treat any change to `tools`, `working_dir`, `setting_sources` or `plugins` as
invalidating earlier numbers. The sealed column should make **zero tool calls** and should
not be climbing toward the plugin column, which reads like the model improving and is
almost always contamination.

---

## Writing a case

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

A case passes at `threshold: 0.8`, averaged across its assertions. **Routing carries
`weight: 3` so a routing miss alone sinks the case**, which unweighted it did not. Three is
the minimum that works across every case size, at the cost of letting two content misses
pass on the five largest cases. Nothing applies the weight for you.

| `type`                                     | Notes                                                                                         |
| ------------------------------------------ | --------------------------------------------------------------------------------------------- |
| `skill-used` / `not-skill-used`            | Reads `metadata.skillCalls`. An errored skill attempt does not satisfy it. Always `weight: 3` |
| `regex` / `not-regex`                      | Any assertion negates with a `not-` prefix                                                    |
| `contains` / `icontains` / `not-icontains` | Case-insensitive variants for one-word answers                                                |
| `llm-rubric`                               | Model-graded against a criterion                                                              |
| `javascript`                               | `file://assertions/*.js`, resolved against the config's directory even from a test file       |

Four traps, each of which has already cost a false result here:

- **Rubrics are graded blind**, on the response text and criterion with no prompt. So "the
  response fixes the loop bound" scores at random: identical output once got `1.00` and
  `0.30`. Grade task success with a `regex`.
- **Only ask for what the prompt supplied.** A rubric wanting per-failure detail from a
  prompt that gave none can never pass.
- **The fixture must stay neutral.** It cannot be empty, or the model asks for code instead
  of writing it. It cannot hint at what a skill teaches either: an earlier pubspec listed
  `bloc`, `flutter_bloc`, `equatable` and `mocktail`, and the sealed column inferred the
  conventions from it, collapsing bloc's measured lift from +10 points to +1.
- **Prompts must be self-contained.** Paste in any class they refer to, and name pasted
  text as authoritative when it describes state not on disk, or a run goes looking and
  answers about the empty fixture.

Prompts name no skill, so `skill-used` is a real routing test, and every skill carries one
negative control asserting `not-skill-used`. The `/<name>` path cannot be measured, since
it expands the skill into the prompt with no `Skill` tool call.

Beyond that: write prompts as a user would send them, grade mechanically where you can,
include the cases where the skill must say no, keep a negative control's rubric to the
absence of the skill's vocabulary, and check an assertion fails in the sealed column before
trusting it.

---

## Running

```bash
P="npx promptfoo@latest"
$P eval -c evals/promptfooconfig.yaml                          # all 100, both columns
$P eval -c evals/promptfooconfig.yaml --filter-pattern bloc    # one skill
$P eval -c evals/promptfooconfig.yaml --filter-providers with-skill
$P eval -c evals/promptfooconfig.yaml --repeat 3 --no-cache    # is a red case real?
$P eval -c evals/promptfooconfig.yaml --retry-errors           # re-run 529s only
$P view                                                        # the side-by-side
```

Read the per-column split, not the total: the sealed column is meant to fail, so about a
third of 200 results failing is healthy. Write runs to the gitignored `evals/.runs/` and
render them with `node evals/ci-summary.js evals/.runs/latest.json`, which buckets errored
results separately so an errored skill reads as thin coverage rather than failure.

**One run is not a measurement**, and these are not a merge gate.

- `--no-cache` for fresh generations. promptfoo caches by default.
- `--repeat 3` before editing anything. Cases drift between 2/3 and 3/3 on their own, and
  two skills were nearly "fixed" off single red reps that turned out to be noise.
- A `529 Overloaded` scores 0 with no failing assertion, indistinguishable from a content
  failure unless you check `res.error`. Follow up with `--retry-errors`.

Budget roughly $0.10 to $0.20 and 10 to 30 seconds per case per provider, so a full
two-column run is a release check rather than an edit-loop one.

---

## Running in CI

`.github/workflows/evals.yaml` runs after a merge to `main`, never on a pull request,
scoped to the changed skills, `with-skill` only, and `continue-on-error`. Each of those
saves money and costs coverage: a regression is reported after it lands, a change that
affects routing globally can be missed, and without the sealed column a case that has
stopped discriminating goes unnoticed. Re-check that deliberately with `include_baseline`.

- Changing `promptfooconfig.yaml`, `assertions/` or `fixture/` widens the scope to all 15
  skills, since any of them affects every case.
- CI needs `ANTHROPIC_API_KEY`, having no Claude Code session. A one-case smoke test runs
  first so auth fails in seconds rather than after a full matrix.
- `max_budget_usd` bounds cost per case, so the ceiling is `cases × columns × budget`:
  about $3.50 for a one-skill merge, $100 for a full two-column run.
- The job has a one-hour ceiling. 100 cases in one column fits, `--repeat 3` does not and
  is cancelled without an artifact. For a full run, use the manual trigger with
  `scope: all-skills`.

---

## What this does not cover

- **Judge calibration.** Most assertions are `llm-rubric` with no human-labelled gold set.
- **Tool execution.** No MCP servers are configured, so the six tool-driven skills are
  graded only on the decisions they narrate.
- **Compilation.** `dart-parses` proves syntax only, via `dart format --output=none` so
  nothing has to resolve. It tries each block as-is, as a statement, and as a bare
  expression before failing it. Keep all three shapes.
- **Stable routing.** Whether a skill activates is nondeterministic, which is why
  `skill-used` is its own assertion rather than inferred from content.
- **Prose in a `SKILL.md`.** Deliberate. An earlier version asserted a hundred `contains`
  patterns against skill bodies, so a copy-edit failed the gate.
- **The skills' own surfaces.** Nothing checks that an `allowed-tools` name exists, that a
  reference link resolves, or that `name` matches the directory. `claude plugin validate .`
  was measured passing with a bogus tool name, a broken link and a `name`/folder mismatch
  all at once. Four invariants are convention alone: `create-project` must not declare
  `Bash`, `green-gate` must declare it for parsing `coverage/lcov.info`, `.mcp.json` must
  keep `--enable dart_format`, and `flutter-reviewer` must declare no write tools. A tool
  name can be correct and still unreachable, so a rename breaks the narration-graded skills
  silently.
