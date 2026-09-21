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

## Cases

What each case asks for is in its own `prompt.md` `description`. These notes record why
the case exists and what separates the two arms.

### testing-structures-unit-tests-as-sentences

**Discriminates.** A bare model writes public `MockApiClient`, a top-level `final` mock
or a `setUp` at the top of `main()`, and names like 'test getUser' with the type spelled
as literal text.

**Note.** `no-mockito` matches the import, not the bare word, so prose naming mockito
still passes. Its pattern omits the `package:` prefix, which was a constraint of the
previous harness that no longer exists, and it is kept unchanged so the numbers stay
comparable.

### testing-declines-mockito

**Discriminates.** A bare model never raises mocktail at all and scores 0.25 here.

### testing-uses-pump-app-in-widget-tests

**Discriminates.** A bare model inlines `pumpWidget(MaterialApp(home: ...))` and
constructs a real bloc, turning the widget test into an integration test.

### testing-avoids-asserting-visual-properties

**Discriminates.** A bare model happily writes the padding/color/font assertions with no
caveat and never mentions golden tests.

### testing-tags-golden-tests-with-a-constant

**Discriminates.** A bare model either omits the tag or passes the raw literal
`tags: 'golden'`.

### testing-stays-out-of-non-test-work

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
