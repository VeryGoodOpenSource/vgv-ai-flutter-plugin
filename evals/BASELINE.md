# Measured baseline

Observed numbers from `claude plugin eval`. Re-measure after any change to a skill
description, a skill body, a prompt, or the fixture. Date new numbers, do not edit these.

```bash
claude plugin eval . --trust-plugin --scaffold \
  --ablation with-without --runs 1 --threshold 0.8 \
  --model claude-sonnet-5 --judge-model claude-sonnet-5 \
  --no-publish --max-cost-usd 45 -j 4
```

`--runs 1` over the whole suite is a shortlist, not a verdict. Confirm anything about a
single case or a single grader with `--runs 3` on both arms.

## Two-arm, 2026-09-17

100 cases, 200 runs, 0 errors, $24.93, 30 minutes at `-j 4`.

|                                 |      value |
| ------------------------------- | ---------: |
| Mean Δ, all 100 cases           |  **+0.65** |
| Mean Δ where the skill routed   |  **+0.76** |
| Routing misses (positive cases) |   **0/84** |
| Cases at or above threshold 0.8 | **97/100** |
| Cases scoring a perfect 1.00    | **85/100** |
| Positive cases with Δ <= 0      |   **0/84** |
| Suite score                     |  **0.971** |

All 15 cases with Δ <= 0 are negative controls, which pass for free without the plugin.
Exclude them when comparing arms.

## One-arm, 2026-09-21

100 cases, 1 run each, 0 errors, $13.35, 10 minutes at `-j 4`.

|                                 |      value |
| ------------------------------- | ---------: |
| Mean case score                 |  **0.961** |
| Cases at or above threshold 0.8 | **94/100** |
| Cases scoring a perfect 1.00    | **83/100** |

Not comparable with the two-arm run: `--ablation none` weights routing graders differently.

## Cases below threshold

Six from the 2026-09-21 run, four re-measured at `--runs 3`.

| case                                                   | 1 run | `--runs 3` | reading             |
| ------------------------------------------------------ | ----: | ---------: | ------------------- |
| `ui-package-declines-hand-rolled-button`               |  0.43 |          — | hit the turn cap    |
| `layered-architecture-wires-repositories-in-bootstrap` |  0.50 |   **0.61** | real, act on this   |
| `green-gate-budgets-per-package-across-a-monorepo`     |  0.62 |          — | matches 2026-09-17  |
| `bloc-writes-sealed-events-and-states`                 |  0.70 |   **1.00** | improved, not cured |
| `green-gate-refuses-to-carry-green-forward`            |  0.71 |   **0.91** | clears on average   |
| `create-project-asks-for-organization-when-required`   |  0.75 |   **0.83** | borderline          |

## Per-skill mean Δ

Two-arm run, 2026-09-17.

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

Every skill clears +0.55, so none is carrying or dragging the suite.

## Grader pass, 2026-09-18

The 2026-09-17 run found 121 content graders passing with no plugin loaded, 28 of them on
these six cases.

| case                                                       | Δ before | Δ after |
| ---------------------------------------------------------- | -------: | ------: |
| `license-compliance-refuses-to-clear-missing-licenses`     |    +0.43 |   +0.86 |
| `internationalization-uses-directional-insets-for-rtl`     |    +0.50 |   +0.86 |
| `bloc-tests-with-bloc-test-and-mocktail`                   |    +0.38 |   +0.75 |
| `layered-architecture-transforms-models-in-the-repository` |    +0.67 |   +0.57 |
| `testing-uses-pump-app-in-widget-tests`                    |    +0.38 |   +0.43 |
| `accessibility-declines-gesture-detector-tap-target`       |    +0.86 |   +0.50 |

The first two are `--runs 3` on both arms. The rest are single-run, so the last two rows
are noise rather than regression.

## Caveats

- **The no-plugin arm swings between runs.** One two-arm run cannot disqualify a grader.
  `accessibility-declines-gesture-detector-tap-target` failed all three content graders
  without the plugin on one run and passed all three on the next.
- **Sonnet judges.** Read the judge's votes in the report before editing a skill.
- **Nothing before 2026-09-17 is comparable.** Earlier numbers ran under a Haiku judge.
- **`create-project` pins `model: haiku`.** Its with-arm answers on a weaker model than its
  baseline, so its Δ is understated. Routing is decided before the switch.
- **`bloc-writes-sealed-events-and-states` still flaps.** Six 1.00s and one 0.70 over seven
  runs, against one in three before the prompt fix. Curing it means `skills/bloc/SKILL.md`
  naming which state approach applies.
- **Tool-driven skills are graded on narration.** No case drives a mocked tool yet.
