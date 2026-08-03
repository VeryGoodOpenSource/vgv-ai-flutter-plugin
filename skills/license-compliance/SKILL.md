---
name: license-compliance
description: >
  Audits package dependency licenses using the Very Good CLI packages_check_licenses
  MCP tool. Flags non-compliant or unknown licenses and produces a compliance summary.
when_to_use: >
  Use when user says "check licenses", "license audit", "are our dependencies compliant",
  "check dependency licenses", "license compliance", "review package licenses",
  "scan for license issues", or "pre-release license check". Use it especially when the
  request asks for a compliance verdict *without* a scan — "read the licenses off this
  pubspec", "confirm we're compliant", "just tell me if these packages are safe to ship",
  "I'd rather not run anything", "which of these are GPL" — because refusing to certify
  from a dependency list is the call this skill governs. A pasted pubspec is a trigger,
  not a substitute for the audit.
argument-hint: "[project-directory]"
allowed-tools: Read Glob Grep mcp__very-good-cli__packages_check_licenses
model: sonnet
effort: medium
---

# License Compliance

Dependency license auditor for Dart and Flutter projects — verifies that all package dependencies use licenses compatible with the project's requirements using the Very Good CLI MCP tools.

---

## Core Standards

Apply these standards to ALL license compliance work:

- **Run `packages_check_licenses` MCP tool** on the target project directory with `licenses: true` to display full license information
- **Pass `directory` to the MCP tool when the project is not at the workspace root** — monorepos with the project in a subdirectory (e.g. `mobile/`) require `directory: 'mobile'`
- **A missing license is not "no license"** — it means "all rights reserved" by default; always flag
- **Transitive dependencies matter** — a permissive package that depends on a GPL package still carries the GPL obligation
- **Only scan output can certify compliance** — never conclude that a project is compliant, clear, or safe to ship from a pubspec dependency list, a package name, a remembered license, or a previous audit. Scan output the user pastes or attaches counts as scan output: take it at face value, audit it, and do not re-run it or question its provenance. The distinction is whether each package arrives with a license attached, not who produced the text
- **Flag for manual review when in doubt** — never assume compliance without a clear license identifier
- **Deliver the report in the prescribed format** — when scan output exists, the answer is the template in [Report Findings](#3-report-findings): the `## License Compliance Report` heading, the summary counts including the total scanned, the flagged table with a risk level and a recommendation per row, and the ranked recommendations. A prose write-up or a bulleted list of packages is not the deliverable, however complete its content

---

## License Categories

| Category | Licenses | Risk | Guidance |
| --- | --- | --- | --- |
| **Permissive** | MIT, BSD-2-Clause, BSD-3-Clause, Apache-2.0 | Low | Safe for any use |
| **Weak copyleft** | LGPL-2.1, LGPL-3.0, MPL-2.0 | Medium | Safe for dynamic linking; flag for static linking or modification |
| **Strong copyleft** | GPL-2.0, GPL-3.0, AGPL-3.0 | High | May require the entire project to adopt the same license |
| **Unknown/Missing** | None detected | High | Flag immediately for manual review |

---

## Audit Process

### 1. Run License Check

Call the `packages_check_licenses` MCP tool on the target project directory. When the project lives in a subdirectory of the workspace (e.g. `mobile/` in a monorepo), pass that path via the `directory` parameter.

### 2. Categorize Results

Classify each dependency license using the categories above. Pay attention to:

- Direct dependencies with strong copyleft licenses
- Transitive dependencies that introduce copyleft obligations
- Packages with no license or an unrecognized license identifier

### 3. Report Findings

Write the report from whatever scan output you have, including output the user pasted into the request. That text is the input to this step, not something to verify first. Report what it says, flag what it flags, and note as its own line that transitive dependencies outside the scanned set are not covered — a caveat inside the report, never a reason to withhold the report.

The report below is a fixed format, not an illustration. Copy the four headings verbatim, keep the `- Total dependencies scanned: N` line even when nothing is flagged, and keep all four table columns including `Recommendation` as its own column. A reader attaches this to a release ticket and diffs it against the previous audit, which only works when every run has the same shape.

```markdown
## License Compliance Report

### Summary
- Total dependencies scanned: N
- Compliant: N
- Flagged: N

### Flagged Dependencies
| Package | License | Risk | Recommendation |
| --- | --- | --- | --- |
| package_name | GPL-3.0 | High | Replace or obtain exception |

### Compliant Dependencies
All other dependencies use permissive licenses (MIT, BSD, Apache 2.0).

### Recommendations
1. [Most urgent action]
2. [Next action]
```

Three ways this comes out wrong, all of which fail the format: prose paragraphs instead of the headings, flagged packages as a bulleted list instead of table rows, and a recommendation folded into the risk cell instead of standing as its own column. One row per flagged package, one recommendation per row.

---

## When the Request Is to Skip the Scan

This section applies to one situation only: the request supplies package **names** with no licenses attached, usually a pubspec `dependencies` block, and asks for a verdict anyway. If each package arrives with a license beside it, that is scan output and the answer is the report in step 3 — go there instead. Refusing to audit real scan output because its provenance is unproven is a failure of this skill, not an application of it.

For the names-only case: "just read the licenses off this list and confirm we're compliant" is the most common form this work arrives in, and the answer is no. A `dependencies` block lists direct dependencies only. The license obligations that sink a release usually come from packages nobody typed into a pubspec: a permissive direct dependency pulling a copyleft transitive one, which appears in the resolved tree and not in that block.

So a pasted dependency list cannot produce a verdict, no matter how well known the packages are. There is no report to write yet either — the template above needs scan output. Reply with the three parts below, in order:

1. **Say the list is not the dependency tree.** Indirect dependencies carry license obligations of their own and are absent from it, so no compliance conclusion can be drawn from what was pasted.
2. **Name the likely licenses if it helps.** Saying `http` and `intl` are BSD-3-Clause is useful orientation and costs nothing, as long as it is framed as what the scan is expected to confirm rather than as the finding.
3. **Give the exact command that produces a real answer.** `packages_check_licenses` with `licenses: true`, or `very_good packages check licenses --licenses` from the project directory, and offer to run it.

Two phrasings to avoid, because both read as certification: "your dependency list looks compliant" and "these are all permissive, so you're clear." Withhold the verdict entirely until the scan output exists.

The same rule covers a scan that ran but came back incomplete. A package whose license the tool could not detect is `Unknown/Missing` and stays flagged. It does not become compliant because its pub.dev page says MIT.
