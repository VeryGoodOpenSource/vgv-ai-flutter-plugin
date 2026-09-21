# accessibility eval notes

## Grading

Mixed grading. `accessibility-wraps-cupertino-and-announces-on-ios` and
`accessibility-adds-non-drag-alternative-to-dismissible` are graded on the artifact,
because they ask for a widget class. The first four cases are graded on what the response
narrates, the question it asks, the report it writes, the request it declines.

Prompts name no skill, so the routing grader catches a routing failure directly.

Prompts are self-contained. The fixture has no source in `lib/`, so a prompt about "my
SettingsView" earns a refusal and every grader fails for an unrelated reason. The widget
under audit is pasted in.

Phases 1 and 2 of the workflow call `AskUserQuestion`, which neither arm exposes, since
`allowed_tools` is `Read, Glob, Grep, Skill`. So the level-and-platform gate is graded on
the question the response *narrates* in text, not on a tool call, the same treatment the
MCP-backed skills get.

Most cases state the WCAG level and the platforms up front. Without them the skill
correctly stops at Phase 1 and asks, which would leave nothing to grade in the
remediation cases. Exactly one case,
`accessibility-asks-level-and-platform-before-auditing`, omits them on purpose, to grade
the gate.

WCAG criterion IDs are graded mechanically, `2.5.8`, `2.1.1` and so on, because Core
Standards pins a specific ID to each rule, and the without-arm tends to answer in generic
"add a label" prose without citing WCAG 2.2 at all.

## Cases

What each case asks for is in its own `prompt.md` `description`. These notes record why
the case exists and what separates the two arms.

### accessibility-asks-level-and-platform-before-auditing

**Discriminates.** The rules under test are SKILL.md's "Never assume AA" and "Begin every
audit by asking which of the six platforms are targeted". An unaided model assumes AA,
audits the widget on the spot, and talks about iOS and Android only. `AA + selected AAA`
is verbatim from the Phase 1 option list and is not phrasing a bare model volunteers.

**Notes.** `names-linux-platform` grades the six-platform list from Phase 2. Linux is the
tell, because an unaided answer talks about iOS and Android, not about Orca on Linux
desktop.

### accessibility-audits-with-criterion-ids-and-severities

**Discriminates.** The report shape comes from `references/audit-templates.md`: per finding
a WCAG ID plus name plus level, a CRITICAL/MAJOR/MINOR severity from the severity guide,
and a before/after fix. The planted 16x16 close button is the 2.5.8 Target Size (Minimum)
violation and its GestureDetector is 2.1.1. An unaided model returns generic "add a label"
prose with no WCAG 2.2 IDs, and grades severity as High/Medium/Low or axe-style
Serious/Moderate rather than the skill's three labels.

**Notes.** `uses-critical-severity-label` grades the upper-case severity labels, which are
the skill's own vocabulary, from the severity guide in `references/audit-templates.md`.

### accessibility-declines-gesture-detector-tap-target

**Discriminates.** The rule is SKILL.md's "Never use bare GestureDetector for tap targets
... GestureDetector is pointer-only and unreachable via keyboard or switch access". The
prompt asks for it by name and supplies a plausible excuse, so complying is the failure
mode. An unaided model obliges, ships the GestureDetector version as its recommendation
with at most a passing caveat, and never cites 2.1.1 Keyboard as the criterion being
broken.

**Notes.** `names-accessible-tap-widget` is the documented replacement list from the
Gesture Detector core standard.

### accessibility-declines-exclude-semantics-on-actionable-content

**Discriminates.** Two rules at once: "Never use ExcludeSemantics on non-decorative
content", and the MergeSemantics correctness rule from `references/examples.md`, which
merges the static label and value pair only and keeps the interactive child independently
focusable. An unaided model either complies with the ExcludeSemantics request or merges
the whole Row, folding the button's role away.

**Notes.** `fix-uses-merge-semantics` includes the opening paren, so the fix has to arrive
as code. The without-arm named MergeSemantics in prose, as a possible cause rather than
the fix.

### accessibility-wraps-cupertino-and-announces-on-ios

**Discriminates.** Two skill facts carry this case: the Cupertino Semantics core standard
("Cupertino widgets ship with weaker semantic defaults ... Always wrap them in
Semantics(label:, value:, button:)"), and the iOS reference's gotcha that
`liveRegion: true` does not auto-announce on iOS, Flutter issue #45968, so
SemanticsService.announce is required as well. An unaided model adds liveRegion and treats
it as sufficient, and either leaves the CupertinoSwitch bare or swaps it for a Material
Switch instead of wrapping it.

### accessibility-adds-non-drag-alternative-to-dismissible

**Discriminates.** Only the criterion ID separates the arms here. The rule is WCAG 2.2
2.5.7, "Every dragging-based function must offer a non-drag alternative on the same
screen. `Dismissible` needs an explicit delete button", and the pattern in
`references/examples.md` keeps the Dismissible and adds a tooltipped IconButton in the
ListTile's trailing slot. A bare model reaches that shape on its own but does not name the
criterion it is remediating. The skill does, everywhere.

**Notes.** `keeps-the-dismissible` exists because the reference pattern keeps the
Dismissible and adds the button beside it, so the swipe must survive the fix.
`labels-the-alternative-control` exists because an icon-only control needs a Tooltip or
Semantics label of its own, from the Icon Buttons core standard and WCAG 4.1.2.
`cites-2-5-7-dragging-movements` is the one assertion the without-arm misses, since Core
Standards pins 2.5.7 to drag alternatives and `references/examples.md` titles the pattern
with it.

### accessibility-stays-out-of-plain-dart-work

**Discriminates.** What must not appear is the skill firing at all, and any Semantics,
semanticLabel, WCAG, screen-reader or accessibility vocabulary in an mm:ss formatter.

**Notes.** `answers-the-question` grades task success mechanically rather than by the
judge. The judge never sees the prompt, so "did it answer the question" is unanswerable
from the output alone.
