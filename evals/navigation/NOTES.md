# navigation eval notes

## Grading

Graded on the artifact. Every case here asks for Dart, so the standards are checked
against the emitted route declarations and call sites rather than against prose about
routing. Nothing in this file can be compiled or run: the generated `*.g.dart` route
helpers never exist in the fixture, and the syntax check the previous harness carried is
gone.

Prompts name no skill, so the routing grader catches a routing failure directly, and
they are self-contained because the fixture has no source in `lib/`.

Rubrics are graded blind: the judge sees the response and the criterion, never the
prompt. So task success is graded with a regex and rubrics are kept to properties
visible in the response text alone.

The trap in this file is neighboring skills. A prompt that reads as generic testing or
generic Flutter work routes to the testing skill instead, which answers with
Navigator.push and never touches GoRouter, so every navigation prompt names the router
and the route explicitly.

Measured baseline, first full run of the original five skills under the previous
harness, negative control excluded: 6/6 with the plugin against 0/6 without it. That arm
split is what to read.

## Cases

What each case asks for is in its own `prompt.md` `description`. These notes record why
the case exists and what separates the two arms.

### navigation-writes-type-safe-routes

**Discriminates.** The baseline writes a flat `GoRoute(path: '/flutter/article/:id')` at
the top level and never mentions code generation.

### navigation-refuses-extra-parameter

**Discriminates.** The baseline demonstrates `extra` as asked, since passing an object
through it is a documented GoRouter feature.

### navigation-uses-hyphens-in-paths

**Discriminates.** The bare model writes `GoRoute(path: '/order-history', builder:)` and
opens it with `context.go('/order-history')`, right hyphen, wrong declaration and wrong
call site.

**Note.** `typed-go-route-annotation` enforces "use `@TypedGoRoute` annotations for
type-safe routes, never raw string paths in route definitions."

**Note.** `hyphenated-path` grades the declared path rather than the noun the model
picks, so `/order-history` and `/purchase-history` both count.

**Note.** `no-underscore-or-camel-path` catches the violations the standard names, an
underscore or a camelCase hump inside a path. It is anchored on `path: '/` so a
camelCase route *name* does not trip it. Both it and `hyphenated-path` allow `/` inside
the path so nested routes are covered; the earlier patterns only reached the first
segment, so `/orders/order_history` slipped past the prohibition and
`/orders/order-history` failed the positive check.

**Note.** `no-raw-path-call-site` enforces "navigate by route name, not raw path
strings". Both sanctioned call sites pass, `context.goNamed('orderHistory')` and
`OrderHistoryRoute().go(context)`. Its pattern holds a backslash and a single quote at
once, so it is double-quoted with doubled backslashes rather than single-quoted.

### navigation-guards-routes-with-redirect

**Discriminates.** The baseline checks auth state inside the page's build method and
pushes /login from there, or wraps the page in a conditional widget.

### navigation-prefers-go-over-push

**Discriminates.** The standard is go() over push(), with push() reserved for when return
data is expected. Nothing is returned here, so any push variant is a failure. The unaided
model answers push(), the opposite of the standard.

**Note.** The whole go family counts, and so does the whole push family: the skill emits
`context.goNamed(...)` here, which a pattern matching only `.go(` would miss.

### navigation-tests-with-mock-go-router

**Discriminates.** The baseline builds a full GoRouter with page builders inside the
test, or asserts on Navigator instead.

### navigation-stays-out-of-non-routing-work

**Discriminates.** Nothing else catches a skill firing where it should not. No GoRoute,
go_router, context.go or ShellRoute may appear, and the prose must not raise routing or
navigation at all.

**Note.** Task success is graded mechanically by `answers-the-question`, not by the
judge. The judge never sees the prompt, so "did it provide the extension" is unanswerable
from the output alone.
