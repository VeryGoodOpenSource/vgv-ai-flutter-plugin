/**
 * Turns a `claude plugin eval` aggregate-result.json into a GitHub step summary.
 *
 *   node evals/_tools/ci-summary.js evals/results/ci/aggregate-result.json [>> $GITHUB_STEP_SUMMARY]
 *
 * Lives in a file rather than inline in the workflow so it can be run against a real
 * result locally, which is the only way to know the field paths still hold after a
 * Claude Code upgrade. The document is versioned (`schemaVersion`) and new fields are
 * added without renaming existing ones, so unknown fields are ignored rather than
 * treated as an error.
 *
 * A run that errored is bucketed separately from a run that scored badly. They are not
 * the same finding: a rate limit, a timeout, or a turn cap produces a 0 with no failing
 * grader, which reads exactly like a content regression unless it is separated out.
 * The skill comes from `cases[].dir`, which is `evals/<skill>/<case>`, so nothing has to
 * guess it by splitting a hyphenated case name.
 */
const fs = require('node:fs');

const SCHEMA_VERSION = 1;

function pct(n) {
  return `${(n * 100).toFixed(0)}%`;
}

function score(n) {
  return typeof n === 'number' ? n.toFixed(2) : '—';
}

function delta(n) {
  if (typeof n !== 'number') return '—';
  const sign = n > 0 ? '+' : '';
  return `${sign}${n.toFixed(2)}`;
}

/**
 * The skill a case belongs to, taken from `cases[].dir`.
 *
 * The suite groups cases as `evals/<skill>/<case>`, so the skill is the segment before
 * the case directory. Several skill names contain hyphens (`dart-flutter-sdk-upgrade`,
 * `very-good-analysis-upgrade`), so splitting the case *name* on `-` gets them wrong and
 * a longest-prefix guess breaks as soon as two skills share a prefix. An ungrouped case
 * sitting directly under the eval directory has no skill to report.
 */
function skillOf(kase) {
  const parts = String(kase.dir || '').split('/').filter(Boolean);
  return parts.length >= 3 ? parts[parts.length - 2] : '—';
}

/** Every error seen across a case's runs, deduplicated, with the arm that produced it. */
function caseErrors(kase) {
  const seen = new Map();
  for (const [arm, runs] of Object.entries(kase.arms || {})) {
    for (const run of runs || []) {
      if (run.error) seen.set(`${arm}: ${run.error}`, true);
      if (run.aborted) {
        const { server, tool, reason } = run.aborted;
        seen.set(`${arm}: mock abort on ${server}/${tool} — ${reason}`, true);
      }
      if (run.skippedPaidGraders) seen.set(`${arm}: judge graders skipped by the cost ceiling`, true);
    }
  }
  return [...seen.keys()];
}

/** The highest-weight failing grader in the with-arm, which is the useful headline. */
function topFailure(kase) {
  let worst = null;
  for (const run of kase.arms?.with || []) {
    for (const g of run.graders || []) {
      if (g.passed || g.scored === false) continue;
      if (!worst || (g.weight || 1) > (worst.weight || 1)) worst = g;
    }
  }
  return worst ? `\`${worst.name}\`: ${worst.explanation || 'failed'}` : '';
}

function main(file) {
  const doc = JSON.parse(fs.readFileSync(file, 'utf8'));

  if (doc.schemaVersion !== SCHEMA_VERSION) {
    console.log(
      `> ⚠️ Result document is schemaVersion ${doc.schemaVersion}, this script was written for ${SCHEMA_VERSION}. Field paths may have moved.\n`,
    );
  }

  const twoArm = doc.suite?.ablation === 'with-without';
  const threshold = doc.suite?.threshold ?? 1;
  const cases = doc.cases || [];

  const errored = cases.filter((c) => caseErrors(c).length > 0);
  const passed = cases.filter((c) => (c.aggregates?.score ?? 0) >= threshold);
  const failed = cases.filter((c) => (c.aggregates?.score ?? 0) < threshold);

  const out = [];
  out.push('### Eval results');
  out.push('');

  if (doc.partial) {
    out.push(`> ⚠️ **Partial run** (\`${doc.partialReason}\`). Scores below are incomplete — leave them out of any trend.`);
    out.push('');
  }

  const bySkill = new Map();
  for (const c of cases) {
    const skill = skillOf(c);
    if (!bySkill.has(skill)) bySkill.set(skill, []);
    bySkill.get(skill).push(c);
  }

  out.push(
    `\`${cases.length}\` case(s) across \`${bySkill.size}\` skill(s) · ` +
      `**${passed.length} at or above ${threshold}**, ${failed.length} below · ` +
      `${errored.length} with a run error · ` +
      `$${(doc.costUsd ?? 0).toFixed(2)} · ${Math.round(doc.durationSeconds ?? 0)}s · CLI ${doc.claudeVersion || '?'}`,
  );
  out.push('');
  out.push(
    `Suite score \`${score(doc.aggregates?.overallScore)}\`` +
      (twoArm ? ` · mean Δ \`${delta(doc.aggregates?.meanDelta)}\` vs the no-plugin baseline` : ' · with-plugin arm only'),
  );
  out.push('');

  const head = twoArm
    ? '| | Case | Skill | With | W/out | Δ | Notes |'
    : '| | Case | Skill | Score | Pass% | Notes |';
  const rule = twoArm ? '| --- | --- | --- | ---: | ---: | ---: | --- |' : '| --- | --- | --- | ---: | ---: | --- |';
  out.push(head);
  out.push(rule);

  for (const [skill, list] of [...bySkill.entries()].sort()) {
    for (const c of list.sort((a, b) => a.name.localeCompare(b.name))) {
      const a = c.aggregates || {};
      const errs = caseErrors(c);
      const ok = (a.score ?? 0) >= threshold;
      const icon = errs.length ? '⚠️' : ok ? '✅' : '❌';
      const note = errs.length ? errs.join('; ') : ok ? '' : topFailure(c);
      const cells = twoArm
        ? [icon, `\`${c.name}\``, skill, score(a.score), score(a.scoreWithout), delta(a.delta), note]
        : [icon, `\`${c.name}\``, skill, score(a.score), pct(a.passRate ?? 0), note];
      out.push(`| ${cells.join(' | ')} |`);
    }
  }

  out.push('');
  if (errored.length) {
    out.push(
      `> ⚠️ ${errored.length} case(s) had a run error. A run that timed out, hit the turn cap, or was rate limited scores 0 with no failing grader, so read those as thin coverage rather than as a regression.`,
    );
    out.push('');
  }
  out.push('One run is not a measurement. Confirm anything red locally with `--runs 3` before acting on it.');

  console.log(out.join('\n'));
}

const file = process.argv[2];
if (!file) {
  console.error('usage: node evals/_tools/ci-summary.js <aggregate-result.json>');
  process.exit(2);
}
main(file);
