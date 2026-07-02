# Changelog

## [0.0.5](https://github.com/VeryGoodOpenSource/vgv-ai-flutter-plugin/compare/v0.0.4...v0.0.5) (2026-07-02)


### Features

* add argument-hint + $ARGUMENTS to sdk-upgrade and analysis-upgrade skills ([#122](https://github.com/VeryGoodOpenSource/vgv-ai-flutter-plugin/issues/122)) ([39fc856](https://github.com/VeryGoodOpenSource/vgv-ai-flutter-plugin/commit/39fc85684d7d58e79724f81b3465f841d19cd931))
* add flutter-reviewer read-only subagent ([#117](https://github.com/VeryGoodOpenSource/vgv-ai-flutter-plugin/issues/117)) ([d513aac](https://github.com/VeryGoodOpenSource/vgv-ai-flutter-plugin/commit/d513aacbf389191c07c6266385d150d6e0276e44))
* add green-gate skill ([#118](https://github.com/VeryGoodOpenSource/vgv-ai-flutter-plugin/issues/118)) ([71f28e7](https://github.com/VeryGoodOpenSource/vgv-ai-flutter-plugin/commit/71f28e7ddbb1aaa654a4e4ac912f5ed69089a45c))


### Bug Fixes

* auto-allow Very Good CLI MCP tools in all run modes ([#120](https://github.com/VeryGoodOpenSource/vgv-ai-flutter-plugin/issues/120)) ([0f3577e](https://github.com/VeryGoodOpenSource/vgv-ai-flutter-plugin/commit/0f3577ed87fdf0f51cc13949f82a7ad25101fd54))


### Docs

* how to test the plugin locally ([#119](https://github.com/VeryGoodOpenSource/vgv-ai-flutter-plugin/issues/119)) ([52c9a8d](https://github.com/VeryGoodOpenSource/vgv-ai-flutter-plugin/commit/52c9a8d7699cbe9ab362ee703838f796d34d6431))

## [0.0.4](https://github.com/VeryGoodOpenSource/vgv-ai-flutter-plugin/compare/v0.0.3...v0.0.4) (2026-06-29)


### Features

* animations skill ([#72](https://github.com/VeryGoodOpenSource/vgv-ai-flutter-plugin/issues/72)) ([70fdbc2](https://github.com/VeryGoodOpenSource/vgv-ai-flutter-plugin/commit/70fdbc2dbc9efcc01a596c8dedb7a4716929cd06))
* **skills:** hint directory parameter for monorepo MCP tool calls ([#90](https://github.com/VeryGoodOpenSource/vgv-ai-flutter-plugin/issues/90)) ([8da150c](https://github.com/VeryGoodOpenSource/vgv-ai-flutter-plugin/commit/8da150ca17e3f8d9d3c90d208478399ce455b847))
* update a11y skill and references ([#89](https://github.com/VeryGoodOpenSource/vgv-ai-flutter-plugin/issues/89)) ([ef057c1](https://github.com/VeryGoodOpenSource/vgv-ai-flutter-plugin/commit/ef057c11a60f5906be2aad6d8ac1f5aea5caf832))


### Bug Fixes

* align skill name frontmatter with folder names ([#106](https://github.com/VeryGoodOpenSource/vgv-ai-flutter-plugin/issues/106)) ([faadf69](https://github.com/VeryGoodOpenSource/vgv-ai-flutter-plugin/commit/faadf690c37fb0e18a3714a4acc15861bccce920))
* correct accessibility skill frontmatter field (when-to-use → when_to_use) ([#102](https://github.com/VeryGoodOpenSource/vgv-ai-flutter-plugin/issues/102)) ([ea9d95c](https://github.com/VeryGoodOpenSource/vgv-ai-flutter-plugin/commit/ea9d95c17fc757d8b6230420960024c47d6184b4))
* require very_good_cli &gt;= 1.3.0 to resolve MCP test hang ([#115](https://github.com/VeryGoodOpenSource/vgv-ai-flutter-plugin/issues/115)) ([54e30b3](https://github.com/VeryGoodOpenSource/vgv-ai-flutter-plugin/commit/54e30b36a0ee1b4b61a708a0cae46846347f27c1))
* **skills:** remove caret syntax in CI for sdk upgrades ([#92](https://github.com/VeryGoodOpenSource/vgv-ai-flutter-plugin/issues/92)) ([7215b7a](https://github.com/VeryGoodOpenSource/vgv-ai-flutter-plugin/commit/7215b7aa4a5e5fb7a3db9be7876c55e721f012fc))
* **skills:** split description and when_to_use, drop unsupported effort field ([#87](https://github.com/VeryGoodOpenSource/vgv-ai-flutter-plugin/issues/87)) ([04357f1](https://github.com/VeryGoodOpenSource/vgv-ai-flutter-plugin/commit/04357f14800eb15419af75da6d017c11bf85d88f))


### Miscellaneous Chores

* update plugin.json description and keywords ([#100](https://github.com/VeryGoodOpenSource/vgv-ai-flutter-plugin/issues/100)) ([09d6575](https://github.com/VeryGoodOpenSource/vgv-ai-flutter-plugin/commit/09d65756f8e4d136c4c45e49b00cc9bc8c86df8d))


### Docs

* document dart MCP server in README and CLAUDE.md ([#114](https://github.com/VeryGoodOpenSource/vgv-ai-flutter-plugin/issues/114)) ([a463370](https://github.com/VeryGoodOpenSource/vgv-ai-flutter-plugin/commit/a46337074c1e4e2cc228ea7abcb4b70d808cce5c))
* fix CLAUDE.md structure block and harden skill-maintenance rules ([#98](https://github.com/VeryGoodOpenSource/vgv-ai-flutter-plugin/issues/98)) ([f3c9a7c](https://github.com/VeryGoodOpenSource/vgv-ai-flutter-plugin/commit/f3c9a7c51f8141eeb605b95da60cd5b505caadc8))
* fix install command and clarify in-session steps in README ([#91](https://github.com/VeryGoodOpenSource/vgv-ai-flutter-plugin/issues/91)) ([4792a9d](https://github.com/VeryGoodOpenSource/vgv-ai-flutter-plugin/commit/4792a9d3af57f22dc3f2248110917e0f6294fe99))
* fix marketplace name in README ([#107](https://github.com/VeryGoodOpenSource/vgv-ai-flutter-plugin/issues/107)) ([5a9cb0b](https://github.com/VeryGoodOpenSource/vgv-ai-flutter-plugin/commit/5a9cb0ba6a42f2238cc63ab7312d5d3fb5dc845b))
* fix README drift for skills, hooks, CLI version, and MCP tool name ([#97](https://github.com/VeryGoodOpenSource/vgv-ai-flutter-plugin/issues/97)) ([ed2c154](https://github.com/VeryGoodOpenSource/vgv-ai-flutter-plugin/commit/ed2c154fe8e7140f13bc0eb1424dfb2441892160))

## [0.0.3](https://github.com/VeryGoodOpenSource/vgv-ai-flutter-plugin/compare/v0.0.2...v0.0.3) (2026-04-22)


### Bug Fixes

* keep pre-1.0.0 releases on patch level (0.0.x) ([#74](https://github.com/VeryGoodOpenSource/vgv-ai-flutter-plugin/issues/74)) ([ac3cc44](https://github.com/VeryGoodOpenSource/vgv-ai-flutter-plugin/commit/ac3cc44705c1ce740f7b2da24498f65372e6fe94))


### Miscellaneous Chores

* change for repo rename ([#78](https://github.com/VeryGoodOpenSource/vgv-ai-flutter-plugin/issues/78)) ([ff2a9c0](https://github.com/VeryGoodOpenSource/vgv-ai-flutter-plugin/commit/ff2a9c06613e436bd5deb639ba102bb0f6637243))


### Docs

* add one-line install command to README ([#85](https://github.com/VeryGoodOpenSource/vgv-ai-flutter-plugin/issues/85)) ([19e78c8](https://github.com/VeryGoodOpenSource/vgv-ai-flutter-plugin/commit/19e78c8dd78779822daff439b010d314a681939f))

## 0.0.1

- Initial release.
