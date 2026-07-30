---
name: license-compliance
description: >
  Audits package dependency licenses using the Very Good CLI packages_check_licenses
  MCP tool. Flags non-compliant or unknown licenses and produces a compliance summary.
when_to_use: >
  Use when user says "check licenses", "license audit", "are our dependencies compliant",
  "check dependency licenses", "license compliance", "review package licenses",
  "scan for license issues", or "pre-release license check".
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
- **Flag for manual review when in doubt** — never assume compliance without a clear license identifier

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

Produce a structured compliance report:

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
