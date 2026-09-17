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
deliberate: a one-word template question does not activate the skill, measured at 0/2 with
the answer correct both times, so grading routing there would only ever report the harness.
Every other case grades routing.

Measured baseline, first full run under the previous harness: 5 of 6 with the skill against 0 of 6 without
it, negative control excluded.

## Cases

What each case asks for is in its own `prompt.md` `description`. These notes record why
the case exists and what separates the two arms.

### create-project-infers-dart-package-for-api-client

**Discriminates.** The inference is that a package with no Flutter dependency takes
dart_package, which is also the layered-architecture rule for data and repository layers.
A bare model reaches for flutter_package because the monorepo is a Flutter one, or answers
with prose instead of a template name.

### create-project-asks-for-organization-when-required

**Discriminates.** The Key Domain Knowledge under test is that app, plugin and game
templates require an organization and silently take a placeholder when it is skipped, so
the skill asks rather than proceeding. A bare model invents com.example, or scaffolds with
the placeholder the template falls back to, and never raises the question.

### create-project-scopes-dependency-install-to-the-new-project

**Discriminates.** A bare model runs the install at the monorepo root, names `flutter
create`, and invents an organization without comment.

**Grader notes.** `names-packages-get` is a regex because both surface forms count: the
MCP tool is `packages_get`, the shell equivalent is `very_good packages get`. An earlier
substring check on `packages_get` failed a correct answer that used the shell form, which
tested syntax rather than knowledge. `directory-points-at-new-project` is the load-bearing
detail in either form, `--directory apps/storefront` or `directory: 'apps/storefront'`;
this is the part a bare model does not know. `no-invented-organization` accepts either
asking for the org or flagging it as required, so it does not demand a specific phrasing.

### create-project-asks-when-the-template-is-ambiguous

**Discriminates.** A bare model picks a template and starts scaffolding, or asks "which
template do you want, dart_package or flutter_package?" — the exact phrasing the skill's
anti-pattern table rules out.

### create-project-does-not-over-ask

**Discriminates.** A bare model runs a questionnaire for description, output directory and
application id before it will do anything.

### create-project-plans-dependency-install

**Discriminates.** The plan has to scaffold through Very Good CLI with an explicit
template and not stop at creation, because dependencies get installed too. A bare model
plans `flutter create my_store --org com.example` and calls it done, leaving the install
out entirely.

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

**Discriminates.** create-project must not be invoked, and none of its vocabulary may
appear: no `very_good create`, no template name, no `--org`, and no suggestion to scaffold
a new project or package around the class.

**Grader notes.** Task success is graded mechanically by `adds-retry-count-field`, not by
the judge. The judge never sees the prompt, so "did it edit the class" is unanswerable
from the output alone.
