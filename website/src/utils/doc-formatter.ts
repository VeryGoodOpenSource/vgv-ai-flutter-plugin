import defineConfig from "../../astro.config.mjs";
import type { CollectionEntry } from "astro:content";

type DocEntry = CollectionEntry<"docs">;

const baseUrl = defineConfig.site;

export function filterDocsBySlug(docs: DocEntry[], slug: string): DocEntry[] {
  return docs.filter((doc) => doc.id.startsWith(`${slug}/`) || doc.id === slug);
}

export function filterDocsBySlugs(
  docs: DocEntry[],
  slugs: string[],
): DocEntry[] {
  docs.map((doc) => console.log("Doc slug: ", doc.id));
  console.log(slugs);

  if (!slugs || slugs.length === 0) {
    return [];
  }

  return docs.filter((doc) => {
    return slugs.some(
      (slug) => doc.id.startsWith(`${slug}/`) || doc.id === slug,
    );
  });
}

export function sortDocs(docs: DocEntry[]): DocEntry[] {
  return docs.sort((a, b) => {
    const orderA = a.data.order ?? 999;
    const orderB = b.data.order ?? 999;
    return orderA - orderB;
  });
}

export function printDocsAsFullText(title: string, docs: DocEntry[]): string {
  return `${title}\n\n${docs
    .map((doc) => {
      return formatDocAsFullText(doc);
    })
    .join("")}`;
}

function formatDocAsFullText(doc: DocEntry): string {
  return `# ${doc.data.title}\n\n${cleanDocBody(doc.body ?? "")}\n\n`;
}

export function cleanDocBody(body: string): string {
  let text = body;

  // Remove ESM import statements (but not Dart/other imports inside code blocks)
  text = text.replace(/^import\s+.*\s+from\s+["'].*["'];?\s*$/gm, "");

  // Convert <Tabs>/<TabItem> to markdown
  text = convertTabsToMarkdown(text);

  // Convert remaining JSX components to markdown
  text = convertJsxToMarkdown(text);

  // Escape special markdown characters
  text = escapeSpecialMarkdownCharacters(text);

  // Clean up excessive blank lines
  text = text.replace(/\n{3,}/g, "\n\n");

  return text.trim();
}

function convertTabsToMarkdown(text: string): string {
  return text.replace(
    /<Tabs>([\s\S]*?)<\/Tabs>/g,
    (_match: string, content: string) => {
      let result = "";

      const tabItemRegex = /<TabItem\s+label="([^"]*)">([\s\S]*?)<\/TabItem>/g;
      let tabMatch;

      while ((tabMatch = tabItemRegex.exec(content)) !== null) {
        const label = tabMatch[1];
        let tabContent = tabMatch[2] ?? "";

        // Dedent by 4 spaces (content was indented inside TabItem)
        tabContent = tabContent.replace(/^    /gm, "");
        tabContent = tabContent.trim();

        result += `${label}:\n${tabContent}\n\n`;
      }
      return result;
    },
  );
}

function convertJsxToMarkdown(text: string): string {
  // Remove self-closing image components
  text = text.replace(/<(?:Diagram|Image|Picture)\b[\s\S]*?\/>/g, "");

  // Strip opening/closing component tags, keeping inner content
  text = text.replace(/<\/?(?:FileTree|Aside|Column|Code)\b[^>]*>/g, "");

  return text;
}

export function printSlugsGrouped(title: string, slugs: string[]): string {
  const tree: Record<string, string[]> = {};
  const topLevelLinks = new Set<string>();

  for (const slug of slugs.sort()) {
    const parts = slug.split("/");

    if (parts.length === 1) {
      const category = parts[0];
      if (category) {
        topLevelLinks.add(category);
        if (!tree[category]) {
          tree[category] = [];
        }
      }
    } else if (parts.length === 2) {
      const category = parts[0];
      const subcategory = parts[1];
      if (category && subcategory) {
        const existingSubcategories = tree[category] || [];
        tree[category] = [...existingSubcategories, subcategory];
      }
    }
  }

  let output = `${title}\n\n`;

  for (const category of Object.keys(tree).sort()) {
    output += `# ${getLinkText(category)}\n\n`;

    if (topLevelLinks.has(category)) {
      output += formatSlugAsLink(category);
    }

    const subcategories = tree[category];

    if (subcategories && subcategories.length > 0) {
      for (const subcategory of subcategories.sort()) {
        output += `## ${getLinkText(subcategory)}\n\n`;
        output += formatSlugAsLink(category, subcategory);
      }
    }
  }

  return output;
}

export function printDocsAsLinks(
  title: string,
  docs: DocEntry[],
  slug: string,
): string {
  const prefixLen = slug.length + 1;

  // Group docs by their first path segment relative to the slug
  const groups = new Map<string, DocEntry[]>();

  for (const doc of docs) {
    if (doc.id === slug) continue;

    const relative = doc.id.slice(prefixLen);
    const firstSegment = relative.split("/")[0] ?? relative;

    if (!groups.has(firstSegment)) {
      groups.set(firstSegment, []);
    }
    groups.get(firstSegment)!.push(doc);
  }

  // If any docs are nested (more than 1 level below slug), use ## headers
  const hasNestedDocs = docs.some((doc) => {
    if (doc.id === slug) return false;
    const relative = doc.id.slice(prefixLen);
    return relative.includes("/");
  });

  let output = `${title}\n\n`;

  const sortedKeys = Array.from(groups.keys()).sort();

  if (hasNestedDocs) {
    for (const key of sortedKeys) {
      output += `## ${getLinkText(key)}\n\n`;
      for (const doc of groups.get(key)!) {
        output += formatDocAsLink(doc);
      }
      output += "\n";
    }
  } else {
    for (const key of sortedKeys) {
      for (const doc of groups.get(key)!) {
        output += formatDocAsLink(doc);
      }
    }
  }

  return output;
}

function formatDocAsLink(doc: DocEntry): string {
  const description = doc.data.description ? `: ${doc.data.description}` : "";
  return `- [${doc.data.title}](${baseUrl}/${doc.id}/llms.txt)${description}\n`;
}

export function printAllDocsAsFullText(
  title: string,
  docs: DocEntry[],
): string {
  // Group docs by top-level category
  const categories = new Map<string, DocEntry[]>();

  for (const doc of docs) {
    const topCategory = doc.id.split("/")[0] ?? doc.id;
    if (!categories.has(topCategory)) {
      categories.set(topCategory, []);
    }
    categories.get(topCategory)!.push(doc);
  }

  let output = `${title}\n\n`;

  for (const category of Array.from(categories.keys()).sort()) {
    output += `## ${getLinkText(category)}\n\n`;

    const categoryDocs = categories.get(category)!;
    const prefixLen = category.length + 1;

    // Group by subcategory within this category
    const groups = new Map<string, DocEntry[]>();

    for (const doc of categoryDocs) {
      const relative = doc.id.slice(prefixLen);
      const firstSegment = relative.split("/")[0] ?? relative;
      if (!groups.has(firstSegment)) {
        groups.set(firstSegment, []);
      }
      groups.get(firstSegment)!.push(doc);
    }

    // If any docs are nested, use ### headers for subcategories
    const hasNestedDocs = categoryDocs.some((doc) => {
      const relative = doc.id.slice(prefixLen);
      return relative.includes("/");
    });

    const sortedKeys = Array.from(groups.keys()).sort();

    if (hasNestedDocs) {
      for (const key of sortedKeys) {
        output += `### ${getLinkText(key)}\n\n`;
        for (const doc of groups.get(key)!) {
          output += `#### ${doc.data.title}\n\n${cleanDocBody(doc.body ?? "")}\n\n`;
        }
      }
    } else {
      for (const key of sortedKeys) {
        for (const doc of groups.get(key)!) {
          output += `### ${doc.data.title}\n\n${cleanDocBody(doc.body ?? "")}\n\n`;
        }
      }
    }
  }

  return output;
}

export function printAllDocsAsLinks(title: string, docs: DocEntry[]): string {
  // Group docs by top-level category
  const categories = new Map<string, DocEntry[]>();

  for (const doc of docs) {
    const topCategory = doc.id.split("/")[0] ?? doc.id;
    if (!categories.has(topCategory)) {
      categories.set(topCategory, []);
    }
    categories.get(topCategory)!.push(doc);
  }

  let output = `${title}\n\n`;

  for (const category of Array.from(categories.keys()).sort()) {
    output += `## ${getLinkText(category)}\n\n`;

    const categoryDocs = categories.get(category)!;
    const prefixLen = category.length + 1;

    // Group by subcategory within this category
    const groups = new Map<string, DocEntry[]>();

    for (const doc of categoryDocs) {
      const relative = doc.id.slice(prefixLen);
      const firstSegment = relative.split("/")[0] ?? relative;
      if (!groups.has(firstSegment)) {
        groups.set(firstSegment, []);
      }
      groups.get(firstSegment)!.push(doc);
    }

    // If any docs are nested, use ### headers for subcategories
    const hasNestedDocs = categoryDocs.some((doc) => {
      const relative = doc.id.slice(prefixLen);
      return relative.includes("/");
    });

    const sortedKeys = Array.from(groups.keys()).sort();

    if (hasNestedDocs) {
      for (const key of sortedKeys) {
        output += `### ${getLinkText(key)}\n\n`;
        for (const doc of groups.get(key)!) {
          output += formatDocAsLink(doc);
        }
        output += "\n";
      }
    } else {
      for (const key of sortedKeys) {
        for (const doc of groups.get(key)!) {
          output += formatDocAsLink(doc);
        }
      }
      output += "\n";
    }
  }

  return output;
}

function formatSlugAsLink(category: string, subcategory?: string): string {
  const title = getLinkText(subcategory || category);

  const path = subcategory
    ? `${category}/${subcategory}/llms.txt`
    : `${category}/llms.txt`;

  return `- [${title}](${baseUrl}/${path})\n\n`;
}

export function getLinkText(slug: string): string {
  // Special case for CI/CD title
  if (slug.toUpperCase() === "CI_CD") {
    return "CI/CD";
  }
  return slug.charAt(0).toUpperCase() + slug.slice(1).replace(/[_-]/g, " ");
}

function escapeSpecialMarkdownCharacters(text: string): string {
  return text.replace(
    /@(immutable|override|TypedGoRoute|TypedStatefulShellRoute)\b/g,
    "\\@$1",
  );
}
