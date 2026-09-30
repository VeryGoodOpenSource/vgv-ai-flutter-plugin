# create-project eval notes

## Grading

`create` is mocked, so the cases assert the call itself. Two grade that it fired with the
right arguments — `create-project-does-not-over-ask` and
`create-project-plans-dependency-install` — and three grade that it did *not* fire while
the organization was missing, the template was ambiguous, or the work belonged to an
existing project. Those three are `min: 0, max: 0` on the mocked tool, which is a real
assertion only because the tool is present to call.

The mock carries an `expect` guard on `subcommand` and `name`, the two fields the real
schema requires. A violation aborts the run at score 0 with no failing grader to read, so
when a case here scores 0 with nothing red, suspect the arguments before the content.

Only assert template names that `SKILL.md` teaches. The mock's `_tools.json` also carries
the enum, but a case that leans on it is grading the manifest rather than the skill.

Read the with-arm score, never Δ: a mocked tool is absent in the no-plugin arm, so its
graders fail for free. `evals/README.md`, "Mocking the MCP servers", has the detail. The
skill also pins `model: haiku`, so its with-arm answers on a weaker model than its
baseline — a second reason Δ understates it.

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
