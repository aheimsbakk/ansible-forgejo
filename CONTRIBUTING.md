# Contributing

For anyone changing the playbook, templates, or target-side scripts.
Running the recipe as an operator is covered in `README.md`.

## Set up the control environment

The quick start in `README.md` creates the virtual environment. The
same environment carries the linter:

```bash
uv venv .venv
uv pip install --python .venv/bin/python -r requirements.txt -r requirements-lint.txt
```

Pin versions in `requirements.txt` and `requirements-lint.txt`; never
use floating tags.

## Change loop

1. Pick where the value belongs:
   - per-deployment (addresses, credentials): `hosts.yml`, untracked;
     document the key in `hosts.yml.example`
   - tracked defaults (image pins, limits, target paths):
     `group_vars/all.yml`
   - application settings: `templates/kube/forgejo.yaml.j2` as
     `FORGEJO__*` variables
   - runner job settings: `templates/runner-config.yaml.j2`; never
     re-run `generate-config` on a target, it wipes the mitigations
2. Verify without changing anything:
   `.venv/bin/ansible-playbook site.yml --check --diff`
3. Apply: `.venv/bin/ansible-playbook site.yml` (or `--tags <area>`)
4. Lint: `.venv/bin/ansible-lint site.yml`. Intentional deviations
   from lint rules carry inline `# noqa` comments; do not silence
   lint any other way.
5. After non-trivial changes run the one-shot checks:
   `.venv/bin/ansible-playbook site.yml --tags verify`

Keep `lan_name` consistent: the value set in the parameter store must
match the pod templates, the target env file, the certificate, and
the runner config. The certificate assertion catches drift.

## Testing on a second host

Use a distinct inventory such as `hosts.test.yml` (untracked) with a
different host name and a different `lan_name`/`static_hostname`
pair: two machines on one LAN announce colliding mDNS names with the
defaults, and fetched certificates are stored per host so test runs
do not overwrite production copies. Set admin credentials only on
the fresh test host.

## Scripts

`scripts/verify_codebase_sync.sh` checks that every repository path
listed in `CODEBASE.md` still exists on disk; it skips target-side
absolute paths and gitignored artifacts.

```bash
scripts/verify_codebase_sync.sh            # checks CODEBASE.md
scripts/verify_codebase_sync.sh CODEBASE.md
```

Run it after adding, moving, or removing files, and update
`CODEBASE.md` (and `BLUEPRINT.md` when architecture changes) in the
same change.

`scripts/bump-version.sh` raises the version in the tracked `VERSION`
file and prints the result. Bump exactly once per finished task:
patch for fixes, minor for features, major for breaking changes.

```bash
scripts/bump-version.sh minor              # 0.1.0 -> 0.2.0
```

`scripts/validate-changelog.sh` checks that `CHANGELOG.md` follows the
project format: version headers `## [X.Y.Z] - YYYY-MM-DD`, the
why/model/tags metadata under each header, and only the category
headings Added, Changed, Fixed, Removed, Security.

```bash
scripts/validate-changelog.sh              # checks CHANGELOG.md
```

## Conventions

- New assertions must state the cause and the fix in the failure
  message; empty or vague messages fail review.
- New side-effecting one-shot tasks go behind the `verify` tag.
- Restart tasks are conditional tasks with `# noqa: no-handler`
  (handlers do not work across `import_tasks`).
- Read `docs/development-notes.md` before touching tasks or
  templates: every entry is a failure that happened on a real
  target.
- Commits follow Conventional Commits (`<type>(<scope>): <summary>`);
  documentation sync commits use `docs(sync):` and precede feature
  commits.

## Documentation split

- `README.md` — what the product is and how an operator runs it.
- `CONTRIBUTING.md` (this file) — change loop, lint, scripts, testing.
- `BLUEPRINT.md` — language-agnostic architecture; update before
  implementing architectural changes.
- `CODEBASE.md` — file-to-component map; update whenever files move.
- `docs/development-notes.md` — traps and patterns per area.
