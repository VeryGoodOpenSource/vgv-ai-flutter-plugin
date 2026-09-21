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

## Full one-arm run, 2026-09-21

100 cases, 1 run each, with-plugin arm, `partial: false`, **$13.35**, 10 minutes at `-j 4`,
models and judge pinned to `claude-sonnet-5`.

|                                 |      value |
| ------------------------------- | ---------: |
| Mean case score                 |  **0.961** |
| Cases at or above threshold 0.8 | **94/100** |
| Cases scoring a perfect 1.00    | **83/100** |
| Usage or auth errors            |      **0** |

Not comparable with the two-arm sweep above: `--ablation none` weights the routing graders
differently.

Six cases came in under 0.8. Re-measured at `--runs 3`, only one holds:
**`layered-architecture-wires-repositories-in-bootstrap` at 0.61**, losing
`constructs-in-bootstrap` on all three runs. `green-gate-refuses-to-carry-green-forward`
(0.91) and `create-project-asks-for-organization-when-required` (0.83) clear or nearly
clear, `ui-package-declines-hand-rolled-button` hit the turn cap rather than failing on
content, and `green-gate-budgets-per-package-across-a-monorepo` matches its 2026-09-17
score.

## `bloc-writes-sealed-events-and-states`, improved 2026-09-18

The case was grading one of two approaches the skill sanctions. `skills/bloc/SKILL.md`
documents a Subclass Approach and a Single Class Approach and chooses by whether the states
carry different data; the graders accept only the first, so a status-enum answer followed
the skill and failed anyway. The prompt now supplies states that carry different data,
which is the skill's own rule.

Readings went from 1.00/0.70/0.60 on the unchanged case to six 1.00s and one 0.70 across
seven post-fix runs. **Improved, not cured.** Making it airtight means the skill naming
which approach a request lifecycle with differing payloads takes, rather than leaving it to
the selection rule. An attempt to fix it by asking for "the whole request lifecycle the UI
will render" made it consistently worse, 0.70 three times out of three.

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

| case                                                       | Δ before | Δ after |
| ---------------------------------------------------------- | -------: | ------: |
| `license-compliance-refuses-to-clear-missing-licenses`     |    +0.43 |   +0.86 |
| `internationalization-uses-directional-insets-for-rtl`     |    +0.50 |   +0.86 |
| `bloc-tests-with-bloc-test-and-mocktail`                   |    +0.38 |   +0.75 |
| `layered-architecture-transforms-models-in-the-repository` |    +0.67 |   +0.57 |
| `testing-uses-pump-app-in-widget-tests`                    |    +0.38 |   +0.43 |
| `accessibility-declines-gesture-detector-tap-target`       |    +0.86 |   +0.50 |

The first two were measured at `--runs 3` on both arms; the rest are single-run and move
several tenths on their own, so the last two rows are noise rather than regression.

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
