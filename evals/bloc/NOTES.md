# bloc eval notes

## Grading

Cases 1, 2, 3 and 5 are graded on the artifact: they ask for Dart and the graders read
the code that comes back. Case 4 is graded on the decision it narrates, two rubrics and
nothing mechanical, because the right answer is a refusal plus an alternative rather
than a snippet.

Prompts name no skill, so the routing grader catches a routing failure directly instead
of leaving it to show up as unexplained content failures downstream.

Prompts are self-contained. The fixture has no source in `lib/`, so a prompt about "my
AuthService" earns a refusal and every grader then fails for an unrelated reason. Paste
the class into the prompt rather than adding source to the fixture, which would leak
answers to the without-plugin arm.

Trap specific to this skill: the fixture pubspec must not list bloc, flutter_bloc,
equatable or mocktail. An earlier version did, the baseline read the dependency list and
inferred the conventions these cases exist to measure, and bloc's measured lift
collapsed from +10 points to +1.

Measured baseline, first full run under the previous harness: 5/5 with the plugin
against 1/5 without it, negative control excluded because a model without the skill
passes the negative routing grader for free.

## Cases

What each case asks for is in its own `prompt.md` `description`. These notes record why
the case exists and what separates the two arms.

### bloc-writes-sealed-events-and-states

**Discriminates.** Sealed classes, Equatable, props and past-tense events are baseline
knowledge, so an unaided model writes them. `LoginInProgress` is the one it misses,
reaching for `LoginLoading` instead, so that is the grader carrying this case.

**Note.** The state naming table pins the four names for exactly this bloc:
`LoginInitial`, `LoginInProgress`, `LoginSuccess`, `LoginFailure`.
`pinned-in-progress-name` is the grader that reads the one the baseline misses.

**Note.** `past-tense-event-names` judges the concrete event subclasses only. An earlier
wording said "every event class name", which the sealed base class `LoginEvent` can never
satisfy, so a correct answer failed on its own base class.

### bloc-tests-with-bloc-test-and-mocktail

**Discriminates.** Without the skill the model writes raw `test()` calls that subscribe
to bloc.stream by hand, and may reach for mockito over mocktail.

**Note.** `imports-mocktail` matches `mocktail/mocktail.dart` rather than the full
`package:mocktail/...` import. The prefix was dropped to work around a previous-harness
limitation that no longer exists, and the pattern is kept unchanged so the numbers stay
comparable.

**Note.** `declares-mock-class` allows a leading underscore because
`skills/bloc/references/testing.md` still shows a public `MockTodoRepository`, so either
form is a faithful reading of the skill.

### bloc-separates-page-from-view

**Discriminates.** Without the skill the model writes one widget that both creates the
bloc and builds the form, which `page-view-split` rejects by name.

### bloc-refuses-bloc-to-bloc-dependency

**Discriminates.** Without the skill the model obliges with a `BlocProvider.value` or a
constructor taking AuthBloc, and never says the pattern is banned.

### bloc-upgrades-cubit-to-bloc-for-transforms

**Discriminates.** Without the skill the model keeps the Cubit and debounces with a
Timer inside it, or pushes the debounce into the widget.

### bloc-stays-out-of-plain-dart-work

**Discriminates.** Must NOT appear: the skill in the tool calls, any flutter_bloc widget
or `extends Bloc<`/`extends Cubit<`, blocTest, or state-management framing in the prose.
Nothing else catches the skill over-firing.

**Note.** Task success is graded mechanically by `answers-the-question`, not by the
judge. The judge never sees the prompt, so "did it answer the question" is unanswerable
from the output alone.
