# animations eval notes

## Grading

Graded on the artifact. Five cases ask for Dart and grade the code that comes back.
`animations-reviews-planted-violations` is the exception, because it asks for a list of
findings and is graded on the review prose. The negative control asks for Dart too, but
grades the absence of motion vocabulary.

Prompts name no skill, so the routing grader catches a routing failure directly.

The load-bearing thing this skill teaches is Material 3 motion tokens. SKILL.md says never
hardcode `Duration(milliseconds: ...)` or use `Curves.*` for new code, and the bare model
hardcodes both every time. So most cases grade tokens twice, once positively with
`Durations.` and `Easing.`, and once as the absence of the forbidden form.

Trap: every hardcoded-value negative is anchored to the argument position, `duration:
Duration(` or `curve: Curves.`, never to the bare type name. An unanchored
`Duration\(milliseconds:` also fires on a response that names the bad form in a comment
while writing the good one, which is a false failure.

Not measurable here: the Core Standard "Clarify visual intent when the request is
ambiguous". A single-shot harness gives the model nobody to ask, so a deliberately vague
prompt grades the harness rather than the skill.

## Cases

What each case asks for is in its own `prompt.md` `description`. These notes record why
the case exists and what separates the two arms.

### animations-uses-m3-motion-tokens-for-implicit-animation

**Discriminates.** Without the skill the model reaches for a StatefulWidget with an
AnimationController and hardcodes 300ms and Curves.easeOut.

**Notes.** `no-hardcoded-duration-or-curve` is the Anti-Patterns section's "Hardcoded
magic values" example, inverted. Four cases carry a grader of this name and the four
patterns deliberately differ: every one is `not_contains`, so widening them to a shared
union would make each stricter and fail correct answers. `centralizes-motion-constants`
alone forbids `= Duration(milliseconds`, because there the point is that the constant
belongs in one place; a case that may legitimately declare a constant must not inherit
that arm. Reviewed and left diverging on purpose. `no-controller-constructed` anchors on `vsync:`, the
mechanical proof a controller was constructed, with `\s*` because the argument is
sometimes written without the space.

### animations-declines-controller-for-simple-fade

**Discriminates.** Without the skill the model complies. It writes the StatefulWidget, the
controller and the AnimatedBuilder exactly as asked.

**Notes.** `uses-animated-opacity` comes from SKILL.md, Anti-Patterns, "Using explicit
when implicit suffices", where the good form for this exact request is AnimatedOpacity.
`no-controller-constructed` is anchored on `vsync:`, the one argument a constructed
controller cannot omit. Matching AnimationController by name would fail a decline that
explains itself.

### animations-staggers-on-a-single-controller

**Discriminates.** Without the skill the model spins up a controller per animation and
hardcodes each duration, so the two-controller negative fires.

**Notes.** `staggers-with-interval` comes from Performance, Do Not: "Do not create
multiple AnimationController instances for animations that share timing, use Interval on
a single controller." `only-one-controller` is that same rule in mechanical form, two
`AnimationController(` constructions anywhere in the response, with `[\s\S]*` because the
two are lines apart. `uses-single-ticker-mixin` is Core Standards, one controller means
SingleTickerProviderStateMixin. `uses-duration-tokens` tracks
`references/staggered-animations.md`, which drives the controller with `Durations.long2`
and curves each Interval with `Easing.`.

### animations-custom-page-transition-via-go-route-data

**Discriminates.** Without the skill the model wraps the page body in a FadeTransition
inside build, or passes a hand-rolled Duration and Curves value.

**Notes.** `overrides-build-page` grades the mechanism the skill prescribes, an override
of buildPage on the GoRouteData rather than a wrapper widget inside the page's build
method. `uses-emphasized-easing` follows `references/page-transitions.md`, which curves
every page transition with `Easing.emphasizedDecelerate`.

### animations-reviews-planted-violations

**Discriminates.** Four violations are planted: a hardcoded duration and curve, the wrong
ticker mixin, an ExpensiveChart rebuilt every frame, and an animated width. Without the
skill the review stops at the missing dispose and does not mention M3 tokens, the mixin
choice, or the layout cost.

**Note.** Graded on prose, not Dart, because the prompt asks for findings.

**Notes.** `uses-single-ticker-mixin` is Core Standards, SingleTickerProviderStateMixin
for one controller and TickerProviderStateMixin only for several.

### animations-centralizes-motion-constants

**Discriminates.** Without the skill the model either inlines timings per feature or
writes a constants class full of raw `Duration(milliseconds: ...)`, which the third arm of
the negative catches.

**Notes.** `declares-app-motion` comes from Core Standards: "durations, curves, and
offsets go in named constants or a centralized AppMotion class, not inline."
`constants-are-duration-tokens` exists because the constants must themselves be M3 tokens,
not a rename of magic numbers.

### animations-stays-out-of-non-motion-work

**Discriminates.** What must not appear is the skill firing at all, any animation widget
such as AnimationController, AnimatedBuilder, TweenAnimationBuilder or
CustomTransitionPage, and the token vocabulary `Durations.`, `Easing.` and `AppMotion`.
Nothing else catches the skill firing where it should not.

**Notes.** `returns-a-color` and `parses-the-hex-string` grade task success mechanically
rather than by the judge. The judge never sees the prompt, so "did it parse the hex
string" is unanswerable from the output. `parses-the-hex-string` carries `(try)?` because
a correct answer that returns null on bad input uses `int.tryParse`, which a bare
`int\.parse` would fail.
