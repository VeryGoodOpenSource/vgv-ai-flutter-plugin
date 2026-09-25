# green-gate eval notes

## Grading

Both MCP servers are mocked and the fixture seeds `lib/` and `test/`, so one case drives
the loop for real. The other seven still grade narration, and the split is deliberate.

`green-gate-runs-the-four-gates-on-a-green-package` grades the calls: which tool ran each
gate, the arguments it carried, and the order. Everything the mock set can produce is
green, so the only loop it can exercise is the skill's one-pass no-op path.

The seven narration cases cover what green runs cannot reach — a red gate, a weakened
target, a stalled fingerprint, a monorepo — and they grade the decisions the skill
narrates: which tool it says it would call, the arguments it would pass, the order, what
it refuses to weaken, and when it stops and escalates. In those seven, never assert that a
response *called* a tool: their prompts ask for a plan or a verdict, so a call would be
wrong.

Every narration prompt therefore ends by asking for a plan or a verdict rather than for a
run, and every scenario is stated in the prompt rather than left on disk. Prompts
describing a repo also say outright that it is not on disk, or the model spends its answer
on what it cannot find. Note that the fixture now has source in it, so the older
"lib/ only has a .gitkeep" failure mode is gone, but a prompt describing eight packages
still needs to say they are not there.

**Read the with-arm score on the tool-driving case, never Δ.** A mocked tool is absent in
the no-plugin arm, so its `tool_used` graders fail for free and drag the output graders
with them. The case will read as this suite's biggest Δ while mostly measuring that the
plugin supplied the server.

Routing is the dominant failure mode here. On a full run 4 of 6 positive cases missed
routing, and every one of those was a prompt asking *about* the gates rather than for a
run. The cause was legible: on `green-gate-plans-the-four-gates-in-order` the model named
the skill in its own answer ("this is what the green-gate skill automates end to end. Want
me to invoke it?") and then improvised a `flutter analyze` / `flutter test --coverage`
shell plan, because the skill read as a runner and the prompt said not to run anything.
The skill's `description` now claims gate *configuration* questions too, and Core
Standards carries a plan-only directive.

Two things are deliberately absent:

- No Dart-parse grader. No case demands Dart code, so no case has fenced dart blocks to
  parse.
- No negative check on `flutter test`. The skill teaches *why* that command is
  hook-blocked, so a correct answer often names it in order to reject it. The tool-routing
  rule is graded by the MCP tool names instead.

## Cases

What each case asks for is in its own `prompt.md` `description`. These notes record why
the case exists and what separates the two arms.

### green-gate-plans-the-four-gates-in-order

**Discriminates.** Unrouted, the bare model improvises a `flutter analyze` / `flutter test
--coverage` shell plan and puts format before analyze.

**Grader notes.** `names-analyze-files` exists because the analyze gate goes through the
Dart MCP server, not `dart analyze` in Bash. `names-check-ignore` and `names-min-coverage`
are the coverage triple with `applyFixes`; `check_ignore` is the one a bare model never
produces, and omitting it makes the `// coverage:ignore` remedy a silent no-op.

### green-gate-refuses-to-weaken-the-coverage-gate

**Discriminates.** Without the skill the model is agreeable — it drops the threshold to
90, adds the ignore comment, and declares the package clean.

### green-gate-refuses-to-carry-green-forward

**Discriminates.** The rules are "Never cache green" and "exit only on observed numbers":
all four gates re-run in one final round, and the format gate is judged by changed count.
Without the skill the model takes the user's word for the earlier analyze and format
results, checks coverage only, and declares green.

**Grader notes.** `format-judged-by-changed-count` covers the format gate's own trap: the
format tool reports success whether or not it rewrote anything, so the changed count is
the only signal it is green.

### green-gate-excludes-generated-files-instead-of-ignoring-them

**Discriminates.** Without the skill the model endorses the teammate's ignore comments and
suggests settling at a 95–97% target.

**Grader notes.** `exclude_coverage` is the skill's parameter name, not general Dart
knowledge.

**Grader notes.** Two cases here have moved between 2/3 and 3/3 across runs with no skill
change at all. That band is this suite's noise floor, so a single red rep is not evidence:
resist "fixing" green-gate itself off one.

### green-gate-escalates-when-the-loop-stops-making-progress

**Discriminates.** The no-progress trigger has three parts: an unchanged failure
fingerprint stops the loop, a standing "keep retrying" instruction does not override it,
and the escalation report carries per-failure detail plus a decision ask. Without the
skill the model accepts the blanket permission and keeps grinding, or stops with a bare
"4 errors remain" and no decision ask.

**Grader notes.** `names-the-no-progress-trigger` matches the skill's own term for the
comparison that makes "no progress" decidable.

### green-gate-runs-the-four-gates-on-a-green-package

**The only case here that calls anything.** An already-green package, all four gates run,
green confirmed from the numbers observed that round, nothing edited.

**Grader notes.** `calls-analyze-with-fixes` carries `weight: 3` and is the case's point:
`input_match` on `"applyFixes": true` is an argument prose cannot satisfy, where the
narration case's `names-apply-fixes` regex passes on the word alone. `analyze-before-test`
proves gate precedence by `tool_order` rather than by a judge reading a plan. The three
`test-call-*` graders split the coverage triple so a partial miss says which parameter was
dropped.

`edits-nothing` and `writes-nothing` are why `Edit` and `Write` are granted in
`allowed_tools` at all. A `max: 0` grader on a tool the run never granted passes
unconditionally forever; granting them makes "exits without editing a single file" a claim
the run can actually break.

### green-gate-budgets-per-package-across-a-monorepo

**Discriminates.** The monorepo rules are a per-package iteration budget,
continue-on-failure with a per-package report, one shared `min_coverage` with no
per-package override, and pubspec.yaml-walk discovery shared by analyze and test. Without
the skill the model gives a generic "run the tests in each package" plan, invents a
per-package coverage override for the 62% package, and aborts on the first red one.

### green-gate-stays-out-of-plain-function-work

**Discriminates.** Nothing else catches the skill firing where it should not. Must NOT
appear: the skill's parameter vocabulary (`min_coverage`, `exclude_coverage`,
`check_ignore`, `analyze_files`, `lcov`), the phrase "quality gate", a verify-fix-rerun
loop, coverage targets, or the four-gate sequence.

**Grader notes.** Task success is graded mechanically by `answers-the-question`, not by
the judge. The judge never sees the prompt, so "is the merge logic right" is unanswerable
from the output alone.
