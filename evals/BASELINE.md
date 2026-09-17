# Measured baseline

Observed numbers from `claude plugin eval`, not estimates. Re-measure after any change to
a skill description, a skill body, a prompt, or the fixture, and date new numbers rather
than editing these.

```bash
claude plugin eval . --trust-plugin --scaffold \
  --ablation with-without --runs 1 --threshold 0.8 \
  --model claude-sonnet-5 --judge-model claude-sonnet-5 \
  --no-publish --max-cost-usd 40 -j 4
```

`--runs 1` is deliberate for a two-arm sweep: one no-plugin pass is enough to disqualify a
grader, which is what the sweep is for. Anything about a *single* case, whether it
regressed or whether it routes reliably, needs `--runs 3`, because both arms are noisy.

## Two full runs, 2026-09-15, Claude Code 2.1.270

Each is 100 cases, 200 agent runs, 0 run errors, `partial: false`.

|                                 | before fixes | after fixes |
| ------------------------------- | -----------: | ----------: |
| Mean Δ, all 100 cases           |        +0.54 |   **+0.63** |
| Routing misses (positive cases) |        14/83 |    **5/83** |
| Cases at or above threshold 0.8 |       81/100 |  **91/100** |
| Cases scoring a perfect 1.00    |        56/84 |   **69/84** |
| Cases with Δ <= 0               |            8 |       **2** |
| Free graders on low-Δ cases     |           47 |      **27** |
| Cost                            |       $22.02 |      $20.95 |

The free-grader count fell without a single grader being touched: fixing routing lifted
those cases' Δ, which moved 20 graders out of the bucket where they cost signal.

## The finding that mattered

|                     | mean Δ    |
| ------------------- | --------: |
| Skill routed        | **+0.75** |
| Skill did not route | **+0.08** |

**Routing is the binding constraint, not grader quality.** In the first run every one of
the eight zero-lift cases was a routing miss rather than a case whose graders failed to
separate the arms. A skill that activates is worth about three quarters of a case; one
that does not is worth nothing.

All 14 routing misses shared one cause: **the description was written around the happy
path and had no entry point for the request that asks for what the skill forbids.**
`green-gate` described driving a package green but not being told to lower the threshold.
`navigation` described declaring routes but not writing a one-line `onTap` callback.
`internationalization` named ARB files but not "I want to use easy_localization".
Descriptions now trigger on refusal-shaped and call-site-shaped prompts too.

## Per-skill, before to after

| skill                      | before | after |    change |
| -------------------------- | -----: | ----: | --------: |
| green-gate                 |  +0.25 | +0.70 | **+0.46** |
| internationalization       |  +0.49 | +0.79 | **+0.30** |
| create-project             |  +0.55 | +0.81 | **+0.26** |
| ui-package                 |  +0.69 | +0.90 | **+0.20** |
| bloc                       |  +0.51 | +0.66 | **+0.14** |
| material-theming           |  +0.75 | +0.88 |     +0.13 |
| static-security            |  +0.76 | +0.83 |     +0.07 |
| animations                 |  +0.76 | +0.82 |     +0.07 |
| accessibility              |  +0.65 | +0.68 |     +0.02 |
| license-compliance         |  +0.68 | +0.70 |     +0.02 |
| testing                    |  +0.49 | +0.52 |     +0.02 |
| very-good-analysis-upgrade |  +0.78 | +0.78 |      0.00 |
| dart-flutter-sdk-upgrade   |  +0.82 | +0.82 |      0.00 |
| layered-architecture       |  +0.61 | +0.59 |     -0.02 |
| navigation                 |  +0.67 | +0.57 |     -0.10 |

## Changes made after the second run

Three descriptions were rewritten after the 100-case run above, so that run understates
the current state for them. Each was verified individually at `--runs 3`:

| case                                                        | before |               after |
| ----------------------------------------------------------- | -----: | ------------------: |
| `navigation-prefers-go-over-push`                           |    1/3 | **3/3**, score 1.00 |
| `testing-tags-golden-tests-with-a-constant`                 |    2/3 | **3/3**, score 1.00 |
| `layered-architecture-refuses-domain-model-in-data-layer`   |    2/3 | **3/3**, score 1.00 |
| `ui-package-tests-widget-through-pump-app-helper` (control) |      — | **3/3**, score 1.00 |

The ui-package row is the control for a real risk. The `testing` rewrite initially claimed
`"Dart code only"` and "a one-line request naming one widget" as its own triggers. That
literal appears in 22 prompts across 9 skills, only 4 of them testing's, and the second
claim collides with ui-package's explicit tiebreaker. The clause now defers to
`ui-package`, and the control confirms that case still routes there 3/3.

**No full two-arm sweep has been run since those three edits.** Run one before quoting
suite-wide numbers again.

## Known-flaky

`green-gate-refuses-to-carry-green-forward` has measured 0/1, 3/3 and 2/3 routing across
three separate runs with no change to its description in between. Treat any single reading
of it as noise.

## Graders that pass with no plugin loaded

27 content graders still pass in the no-plugin arm on cases below Δ 0.50; another 88 sit
on cases that clear 0.50 anyway, where the case discriminates through its other graders.
That is disqualifying for the grader, not automatically for the case. A grader is only
worth keeping if it can fail in the no-plugin arm.

## Caveats

- **Single run per arm** in both sweeps. Treat any one case's Δ as a shortlist entry, not
  a verdict. Two cases were measured scoring identically across runs with a *different*
  grader failing each time.
- **Every number above was measured with a Haiku judge**, which the suite no longer uses.
  A later 100-case run found Haiku marking two correct answers wrong, both clean passes
  under Sonnet, so the recorded scores understate the suite by an unmeasured amount and are
  not comparable with anything run since. Re-baseline before quoting them.
- **`create-project` pins `model: haiku`** in its `SKILL.md`, and the docs confirm the
  override applies for the rest of the turn. Routing is decided before the switch, so it
  never explains a routing miss, but every answer after the skill fires ran on Haiku while
  the no-plugin arm ran on the pinned sonnet. Its Δ is understated by an unmeasured amount.
- **Partial documents are excluded.** A third sweep was interrupted at 38 of 100 cases
  (`partial: true`, mean Δ +0.62, consistent with the complete run) and is not recorded
  here beyond this note.
