import { generateDocsBySlugs } from "../utils/api_handlers";

const title = "# Very Good Backend Documentation";

const slugs = [
  "architecture",
  "automation",
  "code_review",
  "code_style",
  "documentation",
  "error_handling",
  "internationalization",
  "navigation",
  "security",
  "state_management",
];

export const GET = () => generateDocsBySlugs(title, slugs);
