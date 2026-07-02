import type { APIRoute } from "astro";
import { getCollection } from "astro:content";
import { generateDocsBySlug } from "../../utils/api_handlers";
import { getLinkText } from "../../utils/doc-formatter";

export async function getStaticPaths() {
  const allDocs = await getCollection("docs");
  const paths = new Set<string>();

  allDocs.forEach((doc) => {
    const segments = doc.id.split("/");
    for (let i = 1; i <= segments.length; i++) {
      const path = segments.slice(0, i).join("/");
      paths.add(path);
    }
  });

  return Array.from(paths).map((path) => ({
    params: { slug: path },
  }));
}

export const GET: APIRoute = ({ params }) => {
  const categoryPath = params.slug;

  if (!categoryPath) {
    return new Response("Invalid path", { status: 400 });
  }

  const segments = categoryPath.split("/");
  const lastSegment = segments[segments.length - 1] ?? categoryPath;
  const title = `# Very Good Engineering - ${getLinkText(lastSegment)}`;

  return generateDocsBySlug(title, categoryPath);
};
