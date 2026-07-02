import { generateAllDocsFullText } from "../utils/api_handlers";

export const GET = () =>
  generateAllDocsFullText("# Very Good Engineering Documentation");
