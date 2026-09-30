# green-gate eval notes

## Grading

Both MCP servers are mocked and the fixture seeds `lib/` and `test/`, so one case drives
the loop for real. The rest grade narration, apart from the negative control. The split is
deliberate.

`green-gate-runs-the-four-gates-on-a-green-package` grades the calls: which tool ran each
gate, the arguments it carried, and the order. Everything the mock set can produce is
green, so the only loop it can exercise is the skill's one-pass no-op path.

The narration cases cover what green runs cannot reach — a red gate, a weakened
target, a stalled fingerprint, a monorepo — and they grade the decisions the skill
narrates: which tool it says it would call, the arguments it would pass, the order, what
it refuses to weaken, and when it stops and escalates. In those, never assert that a
response *called* a tool: their prompts ask for a plan or a verdict, so a call would be
wrong. `green-gate-stays-out-of-plain-function-work` is the negative control and asks for a
Dart function rather than either.

**Grade mechanically wherever the check is mechanical.** Twelve judged runs of identical
code showed no `llm` grader here stable — the best passed 11/12, the worst 4/12 — so a case
with several of them fails something most runs regardless of what the skill did. Five were
rewritten as a `regex` on the skill's own vocabulary, each checking one thing, and one
compound rubric was cut to a single condition. What stays `llm` is a genuine judgment call
(a refusal, a decision ask) that a pattern cannot read. When a judge fails a reply that
plainly satisfies its rubric, that is the signal to convert, not to reword.

Every narration prompt therefore ends by asking for a plan or a verdict rather than for a
run, and every scenario is stated in the prompt rather than left on disk. Prompts
describing a repo also say outright that it is not on disk, or the model spends its answer
on what it cannot find. Note that the fixture now has source in it, so the older
"lib/ only has a .gitkeep" failure mode is gone, but a prompt describing eight packages
still needs to say they are not there.

**Read that case's with-arm score, never Δ** — `evals/README.md`, "Mocking the MCP
servers", has the reason. Most of its graders need a mocked tool, so its Δ will be the
largest here while mostly measuring that the plugin supplied the server.

**This case carries the suite's only `tool_order` graders.** The semantics, confirmed on a
real run: `before:` names the tool that must come first and `after:` the one that follows,
and the result reports the trace indices it matched
(`analyze_files@4 precedes dart_format@5`). Read those indices when adding one — a reversed
pair asserts the opposite order and still passes.

**The coverage parse has nowhere to go.** `SKILL.md` sends the loop to read
`coverage/lcov.info` through Bash after the test gate, and the mocked test tool writes no
such file. Expect one wasted turn there, which the case's caps absorb. Seeding a token
lcov.info would fix it at the cost of putting coverage data in every case's workspace.

Routing is the dominant failure mode here. On a full run before the tool-driving case
existed, 4 of the 6 positive cases then present missed routing, and every one of those was a prompt asking *about* the gates rather than for a
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

**Grader notes.** `offers-the-missing-test` is a regex for a Dart code block that names
`formatFree`: the test is either shown or it is not. Its earlier rubric failed replies that
showed the test and also noted the method could be deleted if dead, because it demanded
the test be the only alternative.

### green-gate-refuses-to-carry-green-forward

**Discriminates.** The rules are "Never cache green" and "exit only on observed numbers":
all four gates re-run in one final round, and the format gate is judged by changed count.
Without the skill the model takes the user's word for the earlier analyze and format
results, checks coverage only, and declares green.

**Grader notes.** `format-judged-by-changed-count` covers the format gate's own trap: the
format tool reports success whether or not it rewrote anything, so the changed count is
the only signal it is green. It is a regex on the count vocabulary — `0 changed`, `zero
changes`, `changed count` — because the rule is stated in words a pattern can read, and its
rubric form was failing replies that stated it.

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
comparison that makes "no progress" decidable. `per-failure-detail` asserts the last of the
four fingerprint entries verbatim, `code @ file:line`; a reply that reproduces the fourth
that precisely has listed them all, and a reply that only says "4 errors remain" cannot
match it.

### green-gate-runs-the-four-gates-on-a-green-package

**The only case here that calls anything.** An already-green package, all four gates run,
green confirmed from the numbers observed that round, nothing edited.

**Grader notes.** `calls-analyze-with-fixes` is the case's point: `input_match` on
`"applyFixes": true` is an argument prose cannot satisfy, where the narration case's
`names-apply-fixes` regex passes on the word alone. It is weighted so that a miss on it
alone sinks the case. Recompute that when adding a grader here — an earlier weighting let
the case score exactly at the threshold with its own point missing.

`analyze-before-test` and `format-after-analyze` prove gate precedence by `tool_order`
rather than by a judge reading a plan. The `test-call-*` graders split the arguments
the test gate must carry, so a partial miss says which one was dropped, and each asserts a
value rather than the bare key — `"min_coverage": "1000"` and an empty `exclude_coverage`
both passed the first versions.

`calls-the-format-gate` carries `max: 2`. Some cap is the one-pass no-op path's only
enforcement — without one, a model that loops the gates pointlessly still scores full
marks. It was `max: 1` and that was wrong: `SKILL.md` says a round that rewrites files is
confirmed green on the next round, so a second format call is correct, and a run
that made one scored a false red.

`edits-nothing` and `writes-nothing` are why `Edit` and `Write` are granted in
`allowed_tools` at all. A `max: 0` grader on a tool the run never granted passes
unconditionally forever; granting them makes "exits without editing a single file" a claim
the run can actually break. `Bash` is deliberately **not** granted, which is a departure
from the skill's own tool set: the skill reserves Bash for parsing `coverage/lcov.info`,
the mocked test tool writes no such file, so Bash has no legitimate work in this case and
granting it would let `cat >` write files behind the two `max: 0` graders. The
"`green-gate` must declare `Bash`" invariant in `evals/README.md` governs the skill's
frontmatter, not a case's `allowed_tools`.

### green-gate-budgets-per-package-across-a-monorepo

**Discriminates.** The monorepo rules are a per-package iteration budget,
continue-on-failure, and one shared `min_coverage` with no per-package override. The
pubspec.yaml-walk discovery rule is not graded here: the prompt hands over the package
layout, so nothing needs discovering and a grader asking for the walk restated the prompt. Without
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
