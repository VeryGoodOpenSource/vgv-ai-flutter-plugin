import { getCollection } from "astro:content";

import {
  filterDocsBySlug,
  filterDocsBySlugs,
  sortDocs,
  printDocsAsFullText,
  printDocsAsLinks,
  printAllDocsAsLinks,
  printAllDocsAsFullText,
  printSlugsGrouped,
  cleanDocBody,
} from "./doc-formatter";

export async function generateDocsBySlug(
  title: string,
  slug: string,
): Promise<Response> {
  const docs = await getCollection("docs");

  const filteredDocs = filterDocsBySlug(docs, slug);
  const sortedDocs = sortDocs(filteredDocs);

  const hasChildren = sortedDocs.some((doc) => doc.id.startsWith(`${slug}/`));

  let responseBody: string;

  if (hasChildren) {
    responseBody = printDocsAsLinks(title, sortedDocs, slug);
  } else if (sortedDocs.length === 1) {
    // Single leaf doc — use the doc's own title to avoid duplicates
    const doc = sortedDocs[0]!;
    responseBody = `# ${doc.data.title}\n\n${cleanDocBody(doc.body ?? "")}`;
  } else {
    responseBody = printDocsAsFullText(title, sortedDocs);
  }

  return new Response(responseBody, {
    headers: { "Content-Type": "text/plain; charset=utf-8" },
  });
}

export async function generateDocsBySlugs(
  title: string,
  slugs: string[],
): Promise<Response> {
  const docs = await getCollection("docs");

  const filteredDocs = filterDocsBySlugs(docs, slugs);
  const sortedDocs = sortDocs(filteredDocs);

  const responseBody = printDocsAsFullText(title, sortedDocs);

  return new Response(responseBody, {
    headers: { "Content-Type": "text/plain; charset=utf-8" },
  });
}

export async function generateAllDocsLinks(title: string): Promise<Response> {
  const docs = await getCollection("docs");
  const sortedDocs = sortDocs(docs);

  const responseBody = printAllDocsAsLinks(title, sortedDocs);

  return new Response(responseBody, {
    headers: { "Content-Type": "text/plain; charset=utf-8" },
  });
}

export async function generateAllDocsFullText(
  title: string,
): Promise<Response> {
  const docs = await getCollection("docs");
  const sortedDocs = sortDocs(docs);

  const responseBody = printAllDocsAsFullText(title, sortedDocs);

  return new Response(responseBody, {
    headers: { "Content-Type": "text/plain; charset=utf-8" },
  });
}

export async function generateDocsLinksGrouped(
  title: string,
  slugs: string[],
): Promise<Response> {
  const responseBody = printSlugsGrouped(title, slugs);

  return new Response(responseBody, {
    headers: { "Content-Type": "text/plain; charset=utf-8" },
  });
}
