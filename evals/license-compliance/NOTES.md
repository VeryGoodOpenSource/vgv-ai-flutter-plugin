# license-compliance eval notes

## Grading

No MCP server is available to these runs, so `packages_check_licenses` cannot be called
and every response says so before handing the user a command or a plan. These cases
therefore grade the decisions the skill narrates — which tool it would call, with which
arguments, how it categorizes a license it is shown, the report it produces, and what it
refuses to sign off on. Do not assert that a response *invokes* the MCP tool: that is
unsatisfiable here and would measure the harness. Wiring the real server in is not the fix
either — the fixture is a bare skeleton that is never pub-got, so a real scan has nothing
to resolve. Mocking the server in the native harness is a separate, later piece of work,
and none of these cases assume it.

What cannot be measured here: the audit loop's end-to-end behavior on real scan output,
and the accuracy of its counts. Cases that need scan data paste it into the prompt
instead, which grades categorization and reporting but not retrieval.

Prompts are self-contained. The fixture has no source and its pubspec deliberately lists
almost nothing, so any prompt about "our dependencies" must paste the dependency list or
the scan output in.

These cases have no measured baseline yet — read a first run as calibration rather than as
a verdict on the skill.

Graders keep the source assertion order: routing, mechanical, syntax, judged. No case in
this skill had a syntax assertion.

## Cases

### license-compliance-runs-check-with-full-license-info

**Measures.** That the audit is described as the license check with full license
information, and that the deliverable is the prescribed report with risk levels rather
than a list of licenses.

**Discriminates.** A bare model offers to eyeball the pubspec, or names the check without
the flag that makes it print licenses instead of a count.

**Grader notes.** `names-check-licenses` is a regex so both surface forms of the same
thing count: the `packages_check_licenses` MCP tool and `very_good packages check
licenses`. Matching only one would test syntax. `requests-full-license-info` exists
because Core Standards mandate `licenses: true` so full license information is shown
rather than a bare count. It matches the `licenses: true` argument only. An earlier
version also carried a `--licenses` alternation for "the CLI flag form", but no such
flag exists: the fallback SKILL.md prescribes is
`very_good packages check licenses <dir> --dependency-type direct-main,transitive`. The
dead branch was removed.

`describes-the-compliance-report` grades a report the response has not produced, because
the prompt says nothing can be run in the session. An earlier FAIL branch read "if it
assigns no risk level to the flagged ones", which a literal judge fails on any prospective
answer: with no scan there are no flagged packages to assign anything to. The rubric now
names the two things the described report must have and fails only on their absence, and
says a blank template or skeleton counts.

### license-compliance-scopes-check-to-monorepo-subdirectory

**Measures.** The Core Standard that a project below the workspace root needs a
`directory` argument. The layout is asserted in the prompt rather than built in the
fixture, which must stay one bare app — a `mobile/` directory there would hand the
without-skill arm the same context.

**Discriminates.** A bare model targets the workspace root, where a melos repo has no app
pubspec to resolve.

**History.** The bound on the directory regex was 16, which the `directory parameter:
mobile` form overruns. 24 admits it while still excluding prose that merely has both words
near each other, e.g. "in the root directory, since the app lives in mobile/" (28
characters between them). All four forms verified against node.

**Grader notes.** `directory-points-at-mobile` is the load-bearing detail in any of its
forms: `directory: 'mobile'`, `--directory mobile`, or `directory parameter: mobile`.

### license-compliance-categorizes-and-reports-scan-output

**Measures.** Categorization of scan output it is handed: strong copyleft as high risk,
weak copyleft as medium, and an unrecognized or absent identifier as high risk needing
manual review — written up in the report skeleton the skill prescribes.

**Discriminates.** A bare model writes a flat list with no risk column and no scanned
total, and rates GPL-3.0 and MPL-2.0 alike. It may well flag the two unknowns on its own —
the report shape is where the lift is.

**Grader notes.** The report skeleton is graded twice, by `report-heading` and
`total-scanned-line`. Either alone is one formatting slip away from a false negative.
`names-all-rights-reserved` is the skill's own words for a missing license, and the reason
it must be flagged.

### license-compliance-refuses-to-certify-from-pubspec-alone

**Measures.** The Core Standard that transitive dependencies carry obligations of their
own, so a direct dependency list cannot certify compliance.

**Discriminates.** A bare model recites the five packages' licenses and calls the project
clear, which is what the prompt asks for.

### license-compliance-refuses-to-clear-missing-licenses

**Measures.** The prohibition. Core Standards: a missing license means all rights
reserved, always flag; never assume compliance without a clear license identifier. Graded
with the alternative it must offer.

**Discriminates.** No rule binds a bare model to flag these, so under the ship-tonight
framing it can grant the exception, and it offers no remediation path. Correcting the
premise alone is not enough to pass.

### license-compliance-stays-out-of-unrelated-dart-work

**Measures.** That the skill stays out of ordinary Dart work. Nothing else catches it
firing where it should not.

**Discriminates.** No license names, license categories, copyleft talk or dependency
compliance may appear, and the skill must not be invoked.

**Grader notes.** Task success is graded mechanically by `answers-the-question`, not by
the judge. The prompt hands over the signature, so this is deterministic.

## Dropped in the native migration

Nothing. No case in this skill used the `dart-parses` assertion.
