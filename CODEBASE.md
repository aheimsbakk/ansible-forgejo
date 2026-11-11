# CODEBASE — Physical File Map

Maps the abstract components in `BLUEPRINT.md` to concrete files.
Update this file whenever files are added, moved, or removed, then run
`scripts/verify_codebase_sync.sh`.

## Target Stack

- Control side: Ansible (ansible-core 2.21.5), installed in a local
  uv-managed virtual environment from `requirements.txt` and
  `requirements-lint.txt`.
- Target side: POSIX/bash scripts, systemd units, and pod
  definitions in the Kubernetes-spec form the container engine's
  "kube play" consumes.
- Templating: Jinja2 templates rendered at apply time.
- Naming: kebab-case for files and directories. Tags are lowercase:
  `base`, `forgejo`, `runner`, `verify`. Kube definition file names
  must not contain hyphens: the systemd instance name decodes `-`
  back to `/`.

## Repository Tree

```
AGENTS.md                    agent workflow rules (meta)
BLUEPRINT.md                 architecture specification (meta)
CODEBASE.md                  this map (meta)
CHANGELOG.md                 release history
CONTRIBUTING.md              developer guide: change loop, lint, scripts
README.md                    user documentation: what and how to run
VERSION                      release version (0.1.0)
ansible.cfg                  automation-core settings (inventory path, SSH)
requirements.txt             automation-core pin (control side)
requirements-lint.txt        linter pin (control side)
site.yml                     convergence entry point
hosts.yml.example            parameter store template
hosts.yml                    parameter store, untracked (real values)
hosts.test.yml               second-host test inventory, untracked
group_vars/all.yml           tracked defaults registry
tasks/
  base.yml                   area 1: base readiness
  forgejo.yml                area 2: application, certificate, schedules
  runner.yml                 area 3: CI runner
  verify.yml                 area 4: opt-in operational checks
templates/
  containers.conf.j2         engine defaults
  runner-config.yaml.j2      runner job configuration
  kube/forgejo.yaml.j2       application pod definition
  kube/runner.yaml.j2        runner pod definition
files/
  backup.sh                  backup worker
  cleanup.sh                 cleanup worker
  gen-cert.sh                certificate generator
  forgejo-backup.service     schedule: backup job
  forgejo-backup.timer       schedule: backup trigger
  forgejo-cleanup.service    schedule: cleanup job
  forgejo-cleanup.timer      schedule: cleanup trigger
certs/                       fetched public certificates, untracked
  <inventory-host>/forgejo.crt
repo-templates/
  build-multiarch.yml        workflow template for new repositories
docs/
  operations.md              day-2 operator guide
  restore.md                 restore procedure
  ci-and-registry.md         runner, registry, mirrored actions
  development-notes.md       traps for changing the recipe
  memory/                    cross-session memory store
    INDEX.md                 memory index
    archive/                 memory entries
scripts/
  verify_codebase_sync.sh    validates this file against disk
  bump-version.sh            raises VERSION (patch|minor|major)
  validate-changelog.sh      checks CHANGELOG.md structure
.opencode/                   agent configuration (meta)
.opencode/RULES.md           project constraints (meta)
.gitignore                   excludes parameter store, venv, certs
```

## Blueprint Component → Physical Files

| Blueprint component | Repository file | Deployed on target as |
|---|---|---|
| Parameter store | `hosts.yml.example`, `hosts.yml`, `hosts.test.yml` | not deployed |
| Defaults registry | `group_vars/all.yml` | not deployed (render-time) |
| Convergence sequence | `site.yml` | not deployed |
| Area 1: base readiness | `tasks/base.yml` | effects: hostname, packages, engine, dirs, name responder |
| Area 2: application | `tasks/forgejo.yml` | orchestrates the rows below |
| Area 3: CI runner | `tasks/runner.yml` | orchestrates the runner rows below |
| Area 4: operational checks | `tasks/verify.yml` | one-shot runs only |
| Application service definition | `templates/kube/forgejo.yaml.j2` | `/opt/forgejo/kube/forgejo.yaml` |
| Runner service definition | `templates/kube/runner.yaml.j2` | `/opt/forgejo/kube/runner.yaml` |
| Engine defaults | `templates/containers.conf.j2` | `/etc/containers/containers.conf` |
| Runner job configuration | `templates/runner-config.yaml.j2` | `/srv/forgejo-runner/config.yaml` |
| Environment record (cert input) | written by `tasks/forgejo.yml` | `/opt/forgejo/.env` |
| Certificate generator | `files/gen-cert.sh` | `/opt/forgejo/gen-cert.sh` |
| Backup worker | `files/backup.sh` | `/opt/forgejo/backup.sh` |
| Cleanup worker | `files/cleanup.sh` | `/opt/forgejo/cleanup.sh` |
| Backup schedule | `files/forgejo-backup.service`, `files/forgejo-backup.timer` | `/etc/systemd/system/` |
| Cleanup schedule | `files/forgejo-cleanup.service`, `files/forgejo-cleanup.timer` | `/etc/systemd/system/` |
| Trust artifacts (control copies) | fetched into `certs/<inventory-host>/forgejo.crt` | n/a |
| Engine trust entry | installed by `tasks/forgejo.yml` | `/etc/containers/certs.d/<lan_name>/forgejo.crt` |
| Secrets store (encryption key) | generated on target by `tasks/forgejo.yml` | `/opt/forgejo/secrets/secret_key` |
| Data volume / backup store / runner state / grace record | created by `tasks/base.yml` and the workers | `/srv/forgejo`, `/srv/forgejo-backups`, `/srv/forgejo-runner`, `/var/lib/forgejo-cleanup/` |
| Repository workflow template | `repo-templates/build-multiarch.yml` | not deployed |

## Entry Points

- Full convergence: `.venv/bin/ansible-playbook site.yml`
- Verification only: `.venv/bin/ansible-playbook site.yml --check --diff`
- Area-scoped: add `--tags base|forgejo|runner`
- Operational checks: add `--tags verify` (the `verify` tag carries
  `never`, so it never runs otherwise)
- Lint: `.venv/bin/ansible-lint site.yml`
- Docs/disk sync check: `scripts/verify_codebase_sync.sh`
- Control environment setup: see the README quick start.

## Language Rationale

- Areas use task import with conditional restart tasks, not change
  handlers: handlers do not fire across imported files, so each
  restart is an explicit conditional task marked with a lint
  exemption comment.
- HTTP, socket, and name-resolution assertions run as on-target
  commands, not control-side modules: the checks must execute where
  the certificate is trusted; a control-side web module would need
  the certificate on the control machine.
- Pod definitions are templates even though the engine does not
  interpolate them: the LAN address and name are rendered in at apply
  time, keeping the parameter store the only source of those values.
- The full runner configuration is a tracked template, not generated
  on the target: re-running the generator wipes the mitigation
  settings, so the template is the source of truth and a verification
  task asserts the deployed file kept them.
- Schedules are systemd unit files shipped as static files: they
  contain no variables, so templating them would add noise.
- Operational workers are shell scripts, not tasks: they run on
  their own schedules with no control machine present.
- The parameter store is the inventory file itself: host variables
  there override the tracked defaults with no extra indirection, and
  keeping the file untracked prevents addresses and credentials from
  reaching version control.
