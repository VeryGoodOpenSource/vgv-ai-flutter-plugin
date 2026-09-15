# green-gate eval notes

## Grading

Graded on narration, not on the artifact. No MCP server is available to these runs and the
fixture has no source in `lib/` or `test/`, so the loop this skill exists to run cannot
execute here. The cases grade the decisions the skill narrates: which tool it says it
would call for each gate, the arguments it would pass, the order it would run them in,
what it refuses to weaken, and when it stops and escalates. Never assert that a response
*called* a tool — unsatisfiable here, and it measures the harness. Mocking the MCP servers
in the native harness is a separate, later piece of work, and none of these cases assume
it.

Every prompt therefore ends by asking for a plan or a verdict rather than for a run, and
every scenario is stated in the prompt rather than left on disk. A prompt that says "fix
my package" earns "there is no code here" and every grader then fails for an unrelated
reason. Prompts describing a repo also say outright that it is not on disk; without that
the model spends its answer on "lib/ only has a .gitkeep".

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

Graders keep the source assertion order: routing, mechanical, syntax, judged. No case in
this skill had a syntax assertion.

## Cases

### green-gate-plans-the-four-gates-in-order

**Measures.** The plan-only path: the four gates in analyze, format, test, coverage order,
each through the tool the loop actually calls.

**Discriminates.** Unrouted, the bare model improvises a `flutter analyze` / `flutter test
--coverage` shell plan and puts format before analyze.

**History.** Order is graded by two rubrics, one on the sequence and one on the precedence
rule that produces it. With a single rubric on it, the four tool-name regexes carried a
wrong order over the 0.8 threshold on their own. The unrouted baseline formatted before
analyzing and scored 0.03.

`gates-in-order` used to end its FAIL clause with "or on an unordered list", which made
the response's formatting decide the verdict: the gates in the correct order rendered as
bullets read as "an unordered list" and failed a correct plan. FAIL was broader than the
complement of PASS. It now grades the sequence only, says outright that numbering, bullets,
headings, prose and tables count the same, and reserves the no-sequence FAIL for a response
that names the four gates without saying which runs first.

**Grader notes.** `names-analyze-files` exists because the analyze gate goes through the
Dart MCP server, not `dart analyze` in Bash. `names-check-ignore` and `names-min-coverage`
are the coverage triple with `applyFixes`; `check_ignore` is the one a bare model never
produces, and omitting it makes the `// coverage:ignore` remedy a silent no-op.

### green-gate-refuses-to-weaken-the-coverage-gate

**Measures.** "Never weaken a gate": refuses a lowered target and a coverage-ignore on
reachable code, then offers the missing test instead.

**Discriminates.** Without the skill the model is agreeable — it drops the threshold to
90, adds the ignore comment, and declares the package clean.

### green-gate-refuses-to-carry-green-forward

**Measures.** "Never cache green" and "exit only on observed numbers": all four gates
re-run in one final round, and the format gate judged by changed count.

**Discriminates.** Without the skill the model takes the user's word for the earlier
analyze and format results, checks coverage only, and declares green.

**Grader notes.** `format-judged-by-changed-count` covers the format gate's own trap: the
format tool reports success whether or not it rewrote anything, so the changed count is
the only signal it is green.

### green-gate-excludes-generated-files-instead-of-ignoring-them

**Measures.** Denominator hygiene: generated files leave coverage via the
`exclude_coverage` glob, and the 100% target holds.

**Discriminates.** Without the skill the model endorses the teammate's ignore comments and
suggests settling at a 95–97% target.

**History.** A bare `regex: '100'` used to sit here. It was free — every answer that
discusses coverage prints a 100 somewhere — and a free assertion in a 6-assertion case is
what lets a wrong answer clear 0.8. The target is graded by the second rubric instead. A
fifth assertion on the `references/coverage.md` point that coverage-ignore comments are
honored only for pure Dart runs was dropped after a smoke run: the *unrouted* baseline
satisfied it along with `exclude_coverage` and both rubrics, so the case scored 4/5 = 0.80
and passed with routing failing. At four assertions a routing miss now scores 0.75 and
correctly fails.

**Grader notes.** `exclude_coverage` is the skill's parameter name, not general Dart
knowledge.

### green-gate-escalates-when-the-loop-stops-making-progress

**Measures.** The no-progress trigger: an unchanged failure fingerprint stops the loop, a
standing "keep retrying" instruction does not override it, and the escalation report
carries per-failure detail plus a decision ask.

**Discriminates.** Without the skill the model accepts the blanket permission and keeps
grinding, or stops with a bare "4 errors remain" and no decision ask.

**History.** The iteration cap (default 5, per package) used to be graded here. Dropped:
the no-progress trigger fires at round 3 and the cap is never reached, so a correct answer
has no reason to mention 5 rounds — it measured failing against a response that escalated
correctly.

The report was one five-part rubric (gate, failures, files touched, iteration count,
decision). All-or-nothing on five items could not tell "reported three of five" from
"reported nothing", and it failed a response that named the gate, the failures with
file:line, and the decision. Split so partial compliance scores partially. Two demands
were then dropped from the split rubrics as unmeasurable *from this prompt*, not because
the skill stops teaching them: the prompt named no diagnostic codes and described no
edits, so a response could not list the actual failures or name the files it touched.
Measured failing against a response that escalated correctly, named the no-progress
trigger, and promised the diagnostic codes with file:line. Half of that was later
reversed: Change 2 below pastes the codes in and the per-failure rubric is measurable
again. The files-touched demand stays dropped, since the prompt still describes no edits,
and `SKILL.md` "Escalation" still requires that list on a real run.

Naming the gate and the per-failure detail stay separate rubrics for the same reason:
naming the gate is nearly free once the skill routes, the per-failure detail is the
discriminator, and an AND rubric hides which one moved.

This case was the only red one in a 3x run of the whole suite: 1 pass, 2 fails, one of
them a routing miss. Both fails traced to the prompt, not to the skill, and the two prompt
changes below fixed it at 3/3 with `SKILL.md` untouched. That was verified by ablation —
reverting `SKILL.md` to its pre-change state and re-running 3x gave the identical 1.00 in
every rep — so resist "fixing" green-gate itself off this case. Two other cases here moved
between 2/3 and 3/3 across runs with no skill change at all; that band is this suite's
noise floor, and a single red rep is not evidence.

Change 1: the round history is named as authoritative, the same harness insulation cases 2
and 3 of dart-flutter-sdk-upgrade carry. Without it a run walked the working directory,
found the neutral fixture has no Dart files, and spent the answer on that instead of the
escalation question.

Change 2: the four diagnostics are pasted in. Withholding them made the per-failure rubric
unsatisfiable — three repetitions of a response that escalated correctly, named the gate,
and asked for the missing codes failed it 3/3, because nothing can enumerate detail it was
never given. Softening the rubric to accept a promise was the wrong repair; it would grade
an intention. With the codes present the rubric grades the behavior it names. The codes
are deliberately unlike any example in `SKILL.md`, so a response that pattern-matches an
example instead of reading the prompt shows up as wrong rather than passing.

**Grader notes.** `names-the-no-progress-trigger` matches the skill's own term for the
comparison that makes "no progress" decidable.

### green-gate-budgets-per-package-across-a-monorepo

**Measures.** Monorepo rules: per-package iteration budget, continue-on-failure with a
per-package report, one shared `min_coverage` with no per-package override, and
pubspec.yaml-walk discovery shared by analyze and test.

**Discriminates.** Without the skill the model gives a generic "run the tests in each
package" plan, invents a per-package coverage override for the 62% package, and aborts on
the first red one.

**History.** Two rubrics scored 0.75 on a run that routed and answered correctly, both for
the same reason: they were written as if grading a completed run, and this prompt forbids
one. `continues-past-a-red-package` demanded a per-package result "at the end", which a
plan-only answer can only promise, so it now accepts the promised end-of-run summary as
well as collected results. `discovers-roots-by-pubspec-walk` demanded that the analyzer
roots and the test set match, which a response satisfies by feeding one discovered set
into both gates without ever asserting the equality out loud; it now says so, and lists
what a non-walk discovery looks like so the judge is not left inferring it. Both rubrics
also now open with a one-line framing, since the judge never sees the prompt and "several
packages in one repository" is not recoverable from every response. `SKILL.md` was not
touched: **Recursive / Monorepo** already carries continue-on-failure with a per-package
confirmation and the shared `pubspec.yaml` walk.

### green-gate-stays-out-of-plain-function-work

**Measures.** A self-contained one-function request does not pull in the gate loop.

**Discriminates.** Nothing else catches the skill firing where it should not. Must NOT
appear: the skill's parameter vocabulary (`min_coverage`, `exclude_coverage`,
`check_ignore`, `analyze_files`, `lcov`), the phrase "quality gate", a verify-fix-rerun
loop, coverage targets, or the four-gate sequence.

**Grader notes.** Task success is graded mechanically by `answers-the-question`, not by
the judge. The judge never sees the prompt, so "is the merge logic right" is unanswerable
from the output alone.

## Dropped in the native migration

Nothing. No case in this skill used the `dart-parses` assertion.
