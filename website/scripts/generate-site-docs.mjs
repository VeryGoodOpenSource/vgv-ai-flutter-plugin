// Generates Starlight docs from the plugin's skills.
//
// Source of truth: ../../skills/<name>/SKILL.md (+ references/).
// A skill is published only if its SKILL.md frontmatter contains a `web:` block.
//
//   web:
//     section: best-practices   # or "tooling"
//     title: Bloc               # optional; defaults to a title-cased name
//     order: 2                  # optional; sidebar ordering within the section
//
// Output (all regenerated, never hand-edited):
//   src/content/docs/best-practices/<slug>/index.md        (+ reference sub-pages)
//   src/content/docs/tooling/<slug>.md
//   src/generated/sidebar.mjs                              (imported by astro.config.mjs)
//
// Run with `npm run gen:docs`. Output is deterministic: no timestamps, stable
// ordering, so `git diff --exit-code` is the CI freshness gate.

import { existsSync, mkdirSync, readdirSync, readFileSync, rmSync, statSync, writeFileSync } from "node:fs";
import { dirname, join, relative, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import yaml from "js-yaml";

const __dirname = dirname(fileURLToPath(import.meta.url));
const WEBSITE_DIR = resolve(__dirname, "..");
const REPO_ROOT = resolve(WEBSITE_DIR, "..");
const SKILLS_DIR = join(REPO_ROOT, "skills");
const DOCS_DIR = join(WEBSITE_DIR, "src", "content", "docs");
const GENERATED_DIR = join(WEBSITE_DIR, "src", "generated");
const REPO_BLOB = "https://github.com/VeryGoodOpenSource/vgv-ai-flutter-plugin/blob/main";

const SECTIONS = {
  "best-practices": { label: "Best Practices" },
  tooling: { label: "Tooling & Automation" },
};

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/** Split a markdown file into {data, body} using the leading `---` fence. */
function parseFrontmatter(raw) {
  const match = /^---\r?\n([\s\S]*?)\r?\n---\r?\n?([\s\S]*)$/.exec(raw);
  if (!match) return { data: {}, body: raw };
  return { data: yaml.load(match[1]) ?? {}, body: match[2] };
}

/** Collapse folded/multiline YAML scalars into a single trimmed line. */
function oneLine(value) {
  return String(value ?? "").replace(/\s+/g, " ").trim();
}

function titleCase(slug) {
  const overrides = { ios: "iOS", macos: "macOS", os: "OS", ui: "UI", api: "API", cli: "CLI", rtl: "RTL", wcag: "WCAG" };
  return slug
    .split(/[-_ ]+/)
    .map((word) => overrides[word.toLowerCase()] ?? word.charAt(0).toUpperCase() + word.slice(1))
    .join(" ");
}

/** Extract the first level-1 heading, returning {title, body} with it removed. */
function extractTitle(body) {
  const lines = body.split("\n");
  for (let i = 0; i < lines.length; i++) {
    const h1 = /^#\s+(.+?)\s*$/.exec(lines[i]);
    if (h1) {
      lines.splice(i, 1);
      // Drop one blank line left behind by the removed heading.
      if (lines[i] === "") lines.splice(i, 1);
      return { title: h1[1], body: lines.join("\n") };
    }
    if (lines[i].trim() !== "") break; // stop at first non-blank, non-heading line
  }
  return { title: null, body };
}

/** YAML-safe quoted string for frontmatter values. */
function yamlString(value) {
  return JSON.stringify(String(value));
}

/** Recursively list markdown files under a directory (relative paths). */
function listMarkdown(dir, base = dir) {
  if (!existsSync(dir)) return [];
  const out = [];
  for (const entry of readdirSync(dir).sort()) {
    const full = join(dir, entry);
    if (statSync(full).isDirectory()) out.push(...listMarkdown(full, base));
    else if (entry.endsWith(".md")) out.push(relative(base, full));
  }
  return out;
}

// ---------------------------------------------------------------------------
// Discover published skills and build the source -> output-slug map
// ---------------------------------------------------------------------------

/** Reference files for a skill: `references/**` plus a single `reference.md`. */
function referenceFiles(skillDir) {
  const refs = [];
  const refDir = join(skillDir, "references");
  for (const rel of listMarkdown(refDir)) {
    refs.push({ absPath: join(refDir, rel), relSlug: rel.replace(/\.md$/, "") });
  }
  const single = join(skillDir, "reference.md");
  if (existsSync(single)) refs.push({ absPath: single, relSlug: "reference" });
  return refs;
}

function discoverSkills() {
  const skills = [];
  for (const name of readdirSync(SKILLS_DIR).sort()) {
    const skillDir = join(SKILLS_DIR, name);
    const skillFile = join(skillDir, "SKILL.md");
    if (!statSync(skillDir).isDirectory() || !existsSync(skillFile)) continue;

    const { data, body } = parseFrontmatter(readFileSync(skillFile, "utf8"));
    if (!data.web || data.web.publish === false) continue;

    const section = data.web.section;
    if (!SECTIONS[section]) {
      throw new Error(`skills/${name}: web.section must be one of ${Object.keys(SECTIONS).join(", ")}`);
    }
    skills.push({
      name,
      skillDir,
      skillFile,
      body,
      description: oneLine(data.description),
      whenToUse: oneLine(data.when_to_use),
      argumentHint: data["argument-hint"] ? oneLine(data["argument-hint"]) : "",
      section,
      title: data.web.title ?? titleCase(name),
      order: data.web.order ?? 999,
      refs: section === "best-practices" ? referenceFiles(skillDir) : [],
    });
  }
  skills.sort((a, b) => a.order - b.order || a.name.localeCompare(b.name));
  return skills;
}

/**
 * Map each published source file's absolute path to its site URL, and each URL
 * to its human page title (used to humanize path-like link text).
 */
function buildLinkMap(skills) {
  const urlByPath = new Map();
  const titleByUrl = new Map();
  for (const skill of skills) {
    if (skill.section === "best-practices") {
      const url = `/best-practices/${skill.name}`;
      urlByPath.set(skill.skillFile, url);
      titleByUrl.set(url, skill.title);
      for (const ref of skill.refs) {
        const refUrl = `/best-practices/${skill.name}/${ref.relSlug}`;
        urlByPath.set(ref.absPath, refUrl);
        const { title } = extractTitle(readFileSync(ref.absPath, "utf8"));
        titleByUrl.set(refUrl, title ?? titleCase(ref.relSlug.split("/").pop()));
      }
    } else {
      const url = `/tooling/${skill.name}`;
      urlByPath.set(skill.skillFile, url);
      titleByUrl.set(url, skill.title);
    }
  }
  return { urlByPath, titleByUrl };
}

/** Rewrite internal `.md` links to their published site URLs. */
function rewriteLinks(body, sourceAbsPath, { urlByPath, titleByUrl }) {
  return body.replace(/\[([^\]]*)\]\(([^)]+)\)/g, (whole, text, target) => {
    if (/^(https?:|mailto:|#|\/)/.test(target)) return whole;
    const [path, anchor] = target.split("#");
    if (!path.endsWith(".md")) return whole;
    const url = urlByPath.get(resolve(dirname(sourceAbsPath), path));
    if (!url) return whole;
    // Humanize bare-path link text (e.g. `references/foo.md`) to the page title.
    const stripped = text.replace(/`/g, "").trim();
    const looksLikePath = /(^|\/)[\w.-]+\.md$/.test(stripped) || stripped.startsWith("references/");
    const newText = looksLikePath && titleByUrl.has(url) ? titleByUrl.get(url) : text;
    return `[${newText}](${anchor ? `${url}#${anchor}` : url})`;
  });
}

// ---------------------------------------------------------------------------
// Rendering
// ---------------------------------------------------------------------------

function banner(skill, relFromSkill = "SKILL.md") {
  const path = relFromSkill === "SKILL.md" ? `skills/${skill.name}/SKILL.md` : `skills/${skill.name}/${relFromSkill}`;
  return `<!-- GENERATED FROM ${path} — DO NOT EDIT. Run \`npm run gen:docs\` after editing the skill. -->`;
}

function frontmatterBlock(fields) {
  return ["---", ...Object.entries(fields).filter(([, v]) => v != null && v !== "").map(([k, v]) => `${k}: ${v}`), "---"].join("\n");
}

function renderBestPractice(skill, linkMap, writes) {
  // Drop the skill's leading H1 — Starlight renders the title from frontmatter.
  const { body: bodyNoH1 } = extractTitle(skill.body);
  const overviewBody = rewriteLinks(bodyNoH1, skill.skillFile, linkMap).trim();
  const overview = [
    frontmatterBlock({ title: yamlString(skill.title), description: yamlString(skill.description) }),
    banner(skill),
    "",
    overviewBody,
    "",
  ].join("\n");
  writes.push({ path: join(DOCS_DIR, "best-practices", skill.name, "index.md"), content: overview });

  const items = [{ label: "Overview", slug: `best-practices/${skill.name}` }];
  for (const ref of skill.refs) {
    const raw = readFileSync(ref.absPath, "utf8");
    const { title, body } = extractTitle(raw);
    const refTitle = title ?? titleCase(ref.relSlug.split("/").pop());
    const content = [
      frontmatterBlock({ title: yamlString(refTitle) }),
      banner(skill, `references/${ref.relSlug}.md`.replace("references/reference.md", "reference.md")),
      "",
      rewriteLinks(body, ref.absPath, linkMap).trim(),
      "",
    ].join("\n");
    writes.push({ path: join(DOCS_DIR, "best-practices", skill.name, `${ref.relSlug}.md`), content });
    items.push({ label: titleCase(ref.relSlug.split("/").pop()), slug: `best-practices/${skill.name}/${ref.relSlug}` });
  }
  return { label: skill.title, collapsed: true, items };
}

function renderTooling(skill, writes) {
  const run = skill.argumentHint
    ? `Invoke the \`/${skill.name}\` skill in Claude Code (arguments: \`${skill.argumentHint}\`).`
    : `Invoke the \`/${skill.name}\` skill in Claude Code.`;
  const sections = [
    frontmatterBlock({ title: yamlString(skill.title), description: yamlString(skill.description) }),
    banner(skill),
    "",
    skill.description,
    "",
    ...(skill.whenToUse ? ["## When to use it", "", skill.whenToUse, ""] : []),
    "## How to run it",
    "",
    run,
    "",
    `[View the full skill definition on GitHub](${REPO_BLOB}/skills/${skill.name}/SKILL.md)`,
    "",
  ];
  writes.push({ path: join(DOCS_DIR, "tooling", `${skill.name}.md`), content: sections.join("\n") });
  return { label: skill.title, slug: `tooling/${skill.name}` };
}

// ---------------------------------------------------------------------------
// Sidebar module
// ---------------------------------------------------------------------------

function renderSidebar(bestPractices, tooling) {
  const stringify = (value, indent = 0) => JSON.stringify(value, null, 2).replace(/\n/g, "\n" + " ".repeat(indent));
  return [
    "// GENERATED by scripts/generate-site-docs.mjs — DO NOT EDIT.",
    `export const bestPracticesSidebar = ${stringify({ label: SECTIONS["best-practices"].label, items: bestPractices })};`,
    "",
    `export const toolingSidebar = ${stringify({ label: SECTIONS.tooling.label, items: tooling })};`,
    "",
  ].join("\n");
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

function main() {
  const skills = discoverSkills();
  const linkMap = buildLinkMap(skills);
  const writes = [];
  const bestPractices = [];
  const tooling = [];

  for (const skill of skills) {
    if (skill.section === "best-practices") bestPractices.push(renderBestPractice(skill, linkMap, writes));
    else tooling.push(renderTooling(skill, writes));
  }

  // Wipe and rewrite the generated trees so deletions propagate.
  for (const dir of [join(DOCS_DIR, "best-practices"), join(DOCS_DIR, "tooling")]) {
    rmSync(dir, { recursive: true, force: true });
  }
  mkdirSync(GENERATED_DIR, { recursive: true });

  for (const { path, content } of writes) {
    mkdirSync(dirname(path), { recursive: true });
    writeFileSync(path, content.replace(/\n{3,}/g, "\n\n").replace(/\s*$/, "\n"));
  }
  writeFileSync(join(GENERATED_DIR, "sidebar.mjs"), renderSidebar(bestPractices, tooling));

  console.log(`Generated ${bestPractices.length} best-practice + ${tooling.length} tooling pages from ${skills.length} skills.`);
}

main();
