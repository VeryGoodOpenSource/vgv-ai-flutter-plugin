import { Octokit } from "@octokit/rest";
import { languageColors, type LanguageColor } from "./github_languages";

export type GitHubRepository = {
  name: string;
  organization: string;
  url: string;
  fullName: string;
  description: string;
  stars: number;
  forks: number;
  language: string | null;
  languageColor: LanguageColor | null;
};

export type GitHubRepositories = { [key: string]: GitHubRepository };

export const organizationName = "VGVentures";

// Personal access token environment variable name.
// For locally building this project, make your own PAT and set it in your
// environment under this name.
//
// This secret environment value is already provided for the repository so that
// GitHub actions will run accordingly.
export const VGVENTURES_GITHUB_PAT = "VGVENTURES_GITHUB_PAT";

const octokit = new Octokit({ auth: process.env[VGVENTURES_GITHUB_PAT] });

var vgvRepositoryCache: GitHubRepositories | undefined;
var repositoryCache: GitHubRepositories = {};

/**
 * Gets all public repositories from the VGVentures organization. If already
 * fetched, returns the cached repository data.
 * @returns A map of repository full names (org/repo) to repository data.
 */
export async function getRepositories(): Promise<GitHubRepositories> {
  if (vgvRepositoryCache === undefined) {
    vgvRepositoryCache =
      await fetchOrganizationPublicRepositories(organizationName);
  }

  return vgvRepositoryCache;
}

/**
 * Gets an individual repository. If already fetched, returns the cached
 * repository data.
 * @param owner Repository owner, e.g. "VGVentures"
 * @param repo Repository name: e.g., "bloc_concurrency_demos"
 * @returns Repository information.
 */
export async function getRepository(
  owner: string,
  repo: string,
): Promise<GitHubRepository> {
  const fullName = `${owner}/${repo}`;
  if (owner == organizationName) {
    return (await getRepositories())[fullName]!;
  }

  if (typeof repositoryCache[fullName] === "undefined") {
    repositoryCache[fullName] = await fetchRepository(owner, repo);
  }

  const ghRepo = repositoryCache[fullName]!;
  console.log("Found repository:" + JSON.stringify(ghRepo, null, 2));

  return ghRepo;
}

// Returns a map of repository full names to repository data.
async function fetchOrganizationPublicRepositories(
  organizationName: string,
): Promise<GitHubRepositories> {
  // Get EVERY public repo in the organization.
  const response = await octokit.paginate(
    octokit.repos.listForOrg,
    {
      type: "public",
      per_page: 100,
      org: organizationName,
      headers: {
        "If-None-Match": "",
      },
    },
    (response) => response.data,
  );

  if (!Array.isArray(response)) {
    throw new Error(
      "Unexpected response from GitHub API: " +
        JSON.stringify(response, null, 2),
    );
  }

  // Return a map of repository full names to repository data.
  var repos: GitHubRepositories = {};
  for (const raw of response) {
    const repo = mapRepository(raw);
    repos[repo.fullName] = repo;
    console.log("GitHub Repository: " + JSON.stringify(repo, null, 2));
  }

  return repos;
}

async function fetchRepository(
  owner: string,
  repo: string,
): Promise<GitHubRepository> {
  // fetch single repo info with octokit
  const response = await octokit.repos.get({
    owner,
    repo,
  });

  if (typeof response !== "object" || typeof response.data !== "object") {
    throw new Error(
      "Unexpected response from GitHub API: " +
        JSON.stringify(response, null, 2),
    );
  }

  return mapRepository(response.data);
}

function mapRepository(raw: { [key: string]: any }): GitHubRepository {
  const language = raw["language"];
  const languageColor =
    language != null ? (languageColors[language] ?? null) : null;
  return {
    name: raw["name"],
    organization: organizationName,
    url: raw["html_url"],
    fullName: raw["full_name"],
    description: raw["description"] ?? "",
    stars: raw["stargazers_count"] ?? 0,
    forks: raw["forks"] ?? 0,
    language: raw["language"] ?? "",
    languageColor: languageColor,
  };
}
