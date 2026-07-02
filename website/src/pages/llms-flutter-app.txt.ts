import { generateDocsBySlugs } from "../utils/api_handlers";

const title = "# Very Good Flutter App Documentation";

const slugs = [
  "architecture/architecture",
  "architecture/barrel_files",
  "automation",
  "code_review",
  "code_style",
  "documentation",
  "error_handling",
  "internationalization",
  "navigation",
  "security",
  "state_management",
  "testing",
  "theming",
  "widgets",
];

export const GET = () => generateDocsBySlugs(title, slugs);
