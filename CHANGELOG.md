# Changelog

## [0.1.0] - 2026-11-11

- **why:** Document the architecture, map files to components, move developer content out of the README, and add release tooling.
- **model:** kompis/qwen3.8-flash-next-iq3_s
- **tags:** docs, blueprint, codebase, release

### Added

- `BLUEPRINT.md`: language-agnostic architecture (goals, component hierarchy, data flow, contracts, persistence)
- `CODEBASE.md`: component-to-file map, entry points, implementation notes
- `CONTRIBUTING.md`: change loop, lint rules, test-host workflow, script usage
- `scripts/verify_codebase_sync.sh`: checks `CODEBASE.md` paths against disk
- `scripts/bump-version.sh`: patch/minor/major bumps of the tracked `VERSION` file
- `scripts/validate-changelog.sh`: checks `CHANGELOG.md` structure
- `docs/memory/`: cross-session memory index and archive

### Changed

- `README.md`: moved the "Editing configuration" section and the development-notes pointer to `CONTRIBUTING.md`; README now covers operator content only
