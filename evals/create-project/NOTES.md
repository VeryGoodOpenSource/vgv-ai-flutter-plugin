# create-project eval notes

## Grading

No MCP server is available to these runs, so the cases grade the decisions the skill
drives — template inference, name normalization, what it declines — not the create call.
Only assert template names that `SKILL.md` teaches, never ones the MCP server supplies at
run time.

Consequence worth knowing before writing a case here: with no `create` tool the skill
cannot execute, and every response says so and hands the user a command to run instead.
Do not assert that the response *uses* the MCP tools — that is unsatisfiable in this
environment, and asserting it measured the harness rather than the skill. Wiring the real
server in is not the fix either: `create` would scaffold a project into the fixture on
every run. Mocking the server in the native harness is a separate, later piece of work,
and none of these cases assume it.

`create-project-infers-dart-package-for-api-client` carries no routing grader, and that is
deliberate — see its History line. Every other case grades routing.

Measured baseline, first full run under the previous harness: 5 of 6 with the skill against 0 of 6 without
it, negative control excluded.

Graders keep the source assertion order: routing, mechanical, syntax, judged. No case in
this skill had a syntax assertion.

## Cases

### create-project-infers-dart-package-for-api-client

**Measures.** The template inference itself: a package with no Flutter dependency takes
dart_package, which is also the layered-architecture rule for data and repository layers.

**Discriminates.** A bare model reaches for flutter_package because the monorepo is a
Flutter one, or answers with prose instead of a template name.

**History.** No routing grader on purpose. A one-word template question does not activate
the skill — measured at 0/2 with the answer correct both times — so grading routing here
would only ever report the harness. Routing is covered by the cases below that ask for
scaffolding work. "HTTP only, no Flutter widgets" is stated because the terser version
answered `flutter_package` on some runs.

### create-project-asks-for-organization-when-required

**Measures.** Key Domain Knowledge: app, plugin and game templates require an organization
and silently take a placeholder when it is skipped, so the skill asks for it instead of
proceeding.

**Discriminates.** A bare model invents com.example, or scaffolds with the placeholder the
template falls back to, and never raises the question.

### create-project-scopes-dependency-install-to-the-new-project

**Measures.** The two-step order — create, then install — with the install scoped to the
created project via `directory`, plus the organization prompt.

**Discriminates.** A bare model runs the install at the monorepo root, names `flutter
create`, and invents an organization without comment.

**History.** Replaces an earlier `create-project-normalizes-dashed-project-name` case,
which asked what a dashed project name becomes. It scored 1.00 in *both* columns:
snake_case Dart package names are common knowledge, so the case measured Claude rather
than the skill. This asks instead about the two things a bare model cannot guess — the
`packages_get` tool and that its `directory` points at the new project. The organization
is deliberately withheld: with `for org com.example` in the prompt there is no reason to
discuss the requirement, and the plugin column missed the final assertion on every run for
asking about something the prompt had already settled.

**Grader notes.** `names-packages-get` is a regex because both surface forms count: the
MCP tool is `packages_get`, the shell equivalent is `very_good packages get`. An earlier
substring check on `packages_get` failed a correct answer that used the shell form, which
tested syntax rather than knowledge. `directory-points-at-new-project` is the load-bearing
detail in either form, `--directory apps/storefront` or `directory: 'apps/storefront'`;
this is the part a bare model does not know. `no-invented-organization` accepts either
asking for the org or flagging it as required, so it does not demand a specific phrasing.

### create-project-asks-when-the-template-is-ambiguous

**Measures.** That a genuinely ambiguous request gets a clarifying question, framed around
what the user is building rather than a subcommand name.

**Discriminates.** A bare model picks a template and starts scaffolding, or asks "which
template do you want, dart_package or flutter_package?" — the exact phrasing the skill's
anti-pattern table rules out.

### create-project-does-not-over-ask

**Measures.** The other half of the asking rule: with name and organization in hand,
nothing optional gets interrogated.

**Discriminates.** A bare model runs a questionnaire for description, output directory and
application id before it will do anything.

### create-project-plans-dependency-install

**Measures.** That the narrated plan scaffolds through Very Good CLI with an explicit
template and does not stop at creation — dependencies get installed.

**Discriminates.** A bare model plans `flutter create my_store --org com.example` and
calls it done, leaving the install out entirely.

**Grader notes.** Both judged graders scored 0 on a response that listed
`very_good create flutter_app my_store --org com.example` followed by `very_good packages
get`, which is the answer the case is looking for. Two rubric holes caused it. The
scaffolding rubric failed on the literal string `flutter create`, which the response only
mentioned as a labeled fallback, so its FAIL clause was wider than the complement of its
PASS clause; it now fails only on the step the response settles on. Both rubrics also said
"the plan", and the response opened by saying it could not execute anything in this
environment, which read to the judge as no plan at all. Both now state that a response
narrating steps it cannot run is judged on the steps it lists.

### create-project-stays-out-of-existing-project-work

**Measures.** That a one-field edit to an existing class leaves the skill dormant.

**Discriminates.** create-project must not be invoked, and none of its vocabulary may
appear: no `very_good create`, no template name, no `--org`, and no suggestion to scaffold
a new project or package around the class.

**Grader notes.** Task success is graded mechanically by `adds-retry-count-field`, not by
the judge. The judge never sees the prompt, so "did it edit the class" is unanswerable
from the output alone.

## Dropped in the native migration

Nothing. No case in this skill used the `dart-parses` assertion.
