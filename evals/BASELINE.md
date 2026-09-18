# Measured baseline

Observed numbers from `claude plugin eval`, not estimates. Re-measure after any change to
a skill description, a skill body, a prompt, or the fixture, and date new numbers rather
than editing these.

```bash
claude plugin eval . --trust-plugin --scaffold \
  --ablation with-without --runs 1 --threshold 0.8 \
  --model claude-sonnet-5 --judge-model claude-sonnet-5 \
  --no-publish --max-cost-usd 45 -j 4
```

`--runs 1` is deliberate for a two-arm sweep over the whole suite: it is a shortlist, not a
verdict. It is **not** enough to disqualify a grader. Measured 2026-09-18, the no-plugin arm
of `accessibility-declines-gesture-detector-tap-target` failed all three content graders on
one run and passed all three on the next. Anything about a single case or a single grader
needs `--runs 3` on both arms.

## Full two-arm run, 2026-09-17, Claude Code 2.1.270

100 cases, 200 agent runs, 0 run errors, `partial: false`, $24.93, 30 minutes at `-j 4`.

|                                 |      value |
| ------------------------------- | ---------: |
| Mean Δ, all 100 cases           |  **+0.65** |
| Mean Δ where the skill routed   |  **+0.76** |
| Routing misses (positive cases) |   **0/84** |
| Cases at or above threshold 0.8 | **97/100** |
| Cases scoring a perfect 1.00    | **85/100** |
| Positive cases with Δ <= 0      |   **0/84** |
| Suite score                     |  **0.971** |

**Routing is solved for now.** Every one of the 84 positive cases activated its skill.
The previous sweep, under a Haiku judge and before the refusal-shaped description fixes,
measured 5 misses out of 83, and the one before that measured 14. There is no
"skill did not route" row in the table above because the population is empty.

## `bloc-writes-sealed-events-and-states`, fixed 2026-09-18

The CI run scored it 0.60, failing `sealed-state-hierarchy`, `pinned-in-progress-name`,
`final-class-subclasses` and `past-tense-event-names`. A first `--runs 3` scored it 1.00,
3/3, which looked like variance. It was not: a later run scored 0.70, so the readings were
1.00, 0.70 and 0.60 on an unchanged case.

**The case was grading one of two approaches the skill sanctions.** `skills/bloc/SKILL.md`
documents a Subclass Approach and a Single Class Approach, and says to choose by whether
the states carry different data. The graders only accept the first, so a model that wrote
the status-enum state was following the skill and failing the case anyway.

The prompt now supplies states that carry different data, which is the skill's own rule for
choosing subclasses: a spinner while in flight, a `User` on success, an error message on
failure. Measured after the change, `--runs 3` on both arms:

|         |                  runs |  mean |
| ------- | --------------------- | ----: |
| with    | 1.00, 1.00, 1.00      |  1.00 |
| without | 0.70, 0.40, 0.60      |  0.57 |

No grader failed in any with-arm run. An intermediate attempt that asked for "the whole
request lifecycle the UI will render" instead made it consistently *worse*, 0.70 three
times out of three, by steering harder toward the enum. The wording has to select the
approach the way the skill selects it, not describe the feature.

## Reading the two numbers that look bad

**15 cases show Δ <= 0.** All 15 are negative controls, and that is the design: a model
with no plugin passes a "must not invoke the skill" check for free, so its without-arm
score is already near perfect and there is no lift to measure. Among the 84 positive
cases, nothing scored Δ <= 0. Exclude negative controls whenever you compare arms.

**121 content graders pass with no plugin loaded.** 28 of those sit on the six positive
cases that clear less than Δ 0.50, which is where a free grader actually costs signal:

- `accessibility-declines-gesture-detector-tap-target`
- `bloc-tests-with-bloc-test-and-mocktail`
- `internationalization-uses-directional-insets-for-rtl`
- `layered-architecture-transforms-models-in-the-repository`
- `license-compliance-refuses-to-clear-missing-licenses`
- `testing-uses-pump-app-in-widget-tests`

Those six cases were the shortlist for the grader pass below.

## Grader pass over the six weakest cases, 2026-09-18

A free grader is still a regression test, so this pass mostly **added** signal rather than
cutting. Four graders were deleted, each for a reason that does not depend on a score: two
exact duplicates of a rubric beside them, one that restates the prompt
(`class WeatherRepository`), and one that is table stakes for the format (`testWidgets`).
An earlier draft of this pass deleted fifteen on a single free reading and had to restore
eleven.

| case                                                       | Δ before | Δ after |
| ---------------------------------------------------------- | -------: | ------: |
| `license-compliance-refuses-to-clear-missing-licenses`     |    +0.43 |   +0.86 |
| `internationalization-uses-directional-insets-for-rtl`     |    +0.50 |   +0.86 |
| `bloc-tests-with-bloc-test-and-mocktail`                   |    +0.38 |   +0.75 |
| `layered-architecture-transforms-models-in-the-repository` |    +0.67 |   +0.57 |
| `testing-uses-pump-app-in-widget-tests`                    |    +0.38 |   +0.43 |
| `accessibility-declines-gesture-detector-tap-target`       |    +0.86 |   +0.50 |

`license-compliance` and `internationalization` were measured at `--runs 3` on both arms.
The rest are single-run readings and move several tenths on their own, so read the last two
rows as noise rather than regression: nothing was removed from `accessibility` that its
remaining graders do not still cover.

Two skills changed because the grader pass found the skill at fault rather than the case.
`skills/bloc/SKILL.md` gained a Core Standard for `build:` constructing the bloc under test,
which is what separated the two arms of `bloc-tests-with-bloc-test-and-mocktail`.

## Per-skill mean Δ

| skill                      | mean Δ |
| -------------------------- | -----: |
| ui-package                 |  +0.79 |
| material-theming           |  +0.73 |
| very-good-analysis-upgrade |  +0.71 |
| animations                 |  +0.69 |
| dart-flutter-sdk-upgrade   |  +0.69 |
| testing                    |  +0.66 |
| green-gate                 |  +0.65 |
| internationalization       |  +0.63 |
| layered-architecture       |  +0.63 |
| bloc                       |  +0.63 |
| license-compliance         |  +0.61 |
| navigation                 |  +0.58 |
| accessibility              |  +0.58 |
| static-security            |  +0.56 |
| create-project             |  +0.56 |

The spread is narrow and every skill clears +0.55, so no skill is currently carrying the
suite or dragging on it. `create-project` sits last partly because its `SKILL.md` pins
`model: haiku`, so its with-arm answers on a weaker model than its baseline. See the
caveats.

## Cases below threshold

| case                                                  | score |     Δ |
| ----------------------------------------------------- | ----: | ----: |
| `static-security-refuses-platform-channel-biometrics` |  0.50 | +0.50 |
| `green-gate-budgets-per-package-across-a-monorepo`    |  0.62 | +0.62 |
| `create-project-does-not-over-ask`                    |  0.75 | +0.50 |

All three routed, and all three carry a healthy Δ, so the skill is firing and helping.
They are graded strictly rather than broken. Confirm any of them with `--runs 3` before
editing, because a single reading of a case is not a measurement.

## Caveats

- **Single run per arm.** Treat any one case's Δ as a shortlist entry, not a verdict.
- **Sonnet judges.** The suite moved off the Haiku judge after it marked two correct
  answers wrong on a 100-case run, both clean passes under Sonnet. Sonnet is not
  infallible either: read the judge's votes in the report before editing a skill.
- **Not comparable with anything before 2026-09-17.** Earlier numbers in this file's
  history were measured under a Haiku judge and before the harness-insulation fixes to
  three prompts, so they understate the suite by an unmeasured amount.
- **`create-project` pins `model: haiku`** in its `SKILL.md`. Routing is decided before
  the switch, so it never explains a routing miss, but every answer after the skill fires
  ran on Haiku while the no-plugin arm ran on Sonnet. Its Δ is understated by an
  unmeasured amount.
- **Tool-driven skills are graded on narration.** `very-good-cli` has a stand-in inside an
  eval run, which changes nothing outside one, and it is reachable, but no case drives it yet, so these skills are still measured on the calls
  they describe rather than the calls they make. See `README.md` → Mocking the MCP
  servers.
