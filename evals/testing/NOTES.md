# testing eval notes

## Grading

Mixed grading. Cases 1, 3 and 5 are graded on the test code that comes back. Cases 2 and
4 are graded on what the response *narrates*: that the standard is surfaced, not that
the request is refused. Prompts name no skill, so the routing grader catches a routing
failure directly rather than as unexplained content failures downstream.

What only the skill supplies: private `_Mock` classes over public ones, `late` + `setUp`
inside a group, test names that read as sentences with `$Type` interpolation,
`package:mocktail` over `package:mockito`, the shared `pumpApp` helper over an inline
`pumpWidget(MaterialApp(...))`, mocked blocs in widget tests, golden tests for visual
properties, and `TestTag` constants over raw tag strings.

Not measurable here: nothing runs the tests, so a green suite is never proven, and the
syntax check the previous harness carried is gone. The two MCP `test` tool standards
(`directory` for monorepos, `timeout_seconds` against a hanging `pumpAndSettle`) are
unmeasured because the harness configures no MCP servers.

Rubrics are graded blind. The judge sees the response text and the criterion, never the
prompt. Task success is therefore graded with a regex, never a rubric.

Measured baseline, first full run under the previous harness: 4/5 with the plugin, 0/5
without it, negative control excluded because a model without the skill passes the
negative routing grader for free.

Graders follow the old assertion order: routing, then mechanical, then judged. The
syntax slot that sat between mechanical and judged is gone, see the last section.

## Cases

### testing-structures-unit-tests-as-sentences

**Measures.** The whole unit-test shape at once: private `_Mock` class, `late` + `setUp`
inside a group, and names that read as sentences with `$Type` interpolation so renames
propagate.

**Discriminates.** A bare model writes public `MockApiClient`, a top-level `final` mock
or a `setUp` at the top of `main()`, and names like 'test getUser' with the type spelled
as literal text.

**Note.** `no-mockito` matches the import, not the bare word, so prose naming mockito
still passes. Its pattern omits the `package:` prefix, which was a constraint of the
previous harness that no longer exists, and it is kept unchanged so the numbers stay
comparable.

### testing-declines-mockito

**Measures.** That the standard is *surfaced* when the user asks for the banned package
by name. Complying is allowed, complying silently is not.

**Discriminates.** A bare model never raises mocktail at all and scores 0.25 here.

**History.** The earlier version asserted that the mockito import was absent plus a
mocktail import present, demanding outright substitution, and flaked 1 run in 3: the
model names mocktail as the standard, then honors the explicit request and offers the
alternative, which is reasonable behavior to reward rather than fail. Routing is
separately flaky here, this case routed 3 of 3 on one pass and failed to route on the
next, taking every downstream assertion with it.

### testing-uses-pump-app-in-widget-tests

**Measures.** Widget tests wrap through the shared `pumpApp` helper and drive the view
with a MockBloc/MockCubit rather than a real bloc.

**Discriminates.** A bare model inlines `pumpWidget(MaterialApp(home: ...))` and
constructs a real bloc, turning the widget test into an integration test.

**History.** "using our existing widget-test helpers" is in the prompt because without
it the skill reached for `pumpWidget(MaterialApp(...))` inline on some runs, failing
both the helper regex and the rubric. The convention under test is still the skill's,
the prompt names no helper.

### testing-avoids-asserting-visual-properties

**Measures.** Test behavior, not properties. Padding, color and font size are golden-test
territory, and the skill must say so.

**Discriminates.** A bare model happily writes the padding/color/font assertions with no
caveat and never mentions golden tests.

**History.** An earlier version demanded the widget test be withheld entirely, which the
skill does not do: it supplies the test the user asked for while stating the assertions
are fragile. `flags-fragile-assertions` grades that it never complies silently.

### testing-tags-golden-tests-with-a-constant

**Measures.** Golden tests carry a tag, and the tag comes from an abstract `TestTag`
class so goldens can be run or updated independently.

**Discriminates.** A bare model either omits the tag or passes the raw literal
`tags: 'golden'`.

### testing-stays-out-of-non-test-work

**Measures.** That a one-line variable rename leaves the skill dormant. Nothing else
catches it firing where it should not.

**Discriminates.** testing must not be invoked, and none of its vocabulary may appear:
no testWidgets, pumpApp, mocktail or setUp bolted onto the rename.

**Note.** Task success is graded mechanically by `answers-the-question` and
`drops-old-name`, not by the judge. The judge never sees the prompt, so "did it rename
the variable" is unanswerable from the output alone.

**Note.** `drops-old-name` matches the declaration form `final usr`, not the bare name.
An earlier version matched the bare name inside word boundaries and fired on a response
that said "renamed `usr` to `user`", scoring a presentation choice as a skill failure.
Anchoring on the declaration also retired the `cspell:ignore` directive the grader used
to carry.

## Dropped in the native migration

The `dart-parses` syntax assertion has no native equivalent, so these cases lost it:

- testing-structures-unit-tests-as-sentences
- testing-uses-pump-app-in-widget-tests
