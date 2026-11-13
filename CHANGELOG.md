# Changelog

## [0.2.1] - 2026-11-13

- **why:** The target is a small host; compressed RAM swap adds memory headroom for containers.
- **model:** kompis/qwen3.8-flash-next-iq3_s
- **tags:** packages, base, memory

### Added

- `tasks/base.yml`: install `systemd-zram-generator` with the engine and discovery packages

## [0.2.0] - 2026-11-11

- **why:** The pinned Forgejo 16.0 line reached end of life on 2026-10-29, so the pins move to the supported 17.0 line and the matching runner.
- **model:** kompis/qwen3.8-flash-next-iq3_s
- **tags:** pins, forgejo, runner, upgrade

### Changed

- `group_vars/all.yml`: Forgejo pin 16.0.5 → 17.0.1; runner pin 13.1.0 → 13.2.1 (17.0 job summaries need runner 13.2 or newer); reserved-username note updated for 17
- `docs/restore.md`: restore-command statement now cites 17.0.1 (verified against the v17.0 backup guide); tested-state notes the drill predates the bump

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
