import { generateAllDocsLinks } from "../utils/api_handlers";

export const GET = () => {
  return generateAllDocsLinks("# Very Good Engineering Documentation Links");
};
