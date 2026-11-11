# BLUEPRINT — Forgejo LAN Instance: Deployment Automation

Language-agnostic architecture specification. Concrete file paths and
the target stack live in `CODEBASE.md`.

## System Goals

- Bring one Debian-class target machine to a known state running a
  private Forgejo git forge, reachable only on the local network.
- Idempotent convergence: a second run reports no changes; a
  verification-only mode inspects the configuration without touching
  the target.
- Security posture by construction: every published port binds to the
  single LAN address; TLS uses a per-instance self-signed certificate;
  the data-encryption key lives outside backups and version control;
  CI job containers run unprivileged with resource limits.
- Self-maintaining: a nightly backup with fixed retention and a
  nightly disk cleanup with a grace period, scheduled on the target.
- Proven end state: every area of convergence ends with assertions
  that read live state; each failure names its cause and its fix.

## Component Hierarchy

- Control system (runs on the operator's machine)
  - Parameter store — untracked, per-deployment: target address, LAN
    name and address, resolver, access key path, optional fresh-install
    admin credentials.
  - Defaults registry — tracked: name defaults, image version pins,
    resource limits, target-side paths, container user identity.
  - Convergence sequence — ordered areas, each independently
    selectable:
    1. Base readiness: identity, updates, container engine and its
       defaults, directory layout, LAN name announcement.
    2. Application: service definitions, certificate, encryption key,
       app runtime, schedules, engine registry trust, service
       assertions.
    3. CI runner: registration (fresh installs) and job configuration.
    4. Operational checks — opt-in only, never part of a normal run:
       one backup pass, one cleanup pass, registry-trust probe,
       timer-state reads.
- Target runtime (lives on the machine)
  - Application instance: web UI over HTTPS, plain-HTTP redirect to
    the canonical URL, git-over-SSH on a dedicated port, container
    registry on the same host and certificate.
  - Runner instance: no published ports; dials the instance outbound
    over HTTPS; starts job containers through the engine.
  - Operational workers: certificate generator, backup worker, cleanup
    worker; run under time-based schedules (cleanup deliberately
    after backup).
- Trust artifacts
  - Public certificate copies collected on the control machine, one
    per instance, for client pinning.
  - Engine trust entry so the target itself can pull from the
    instance registry.

## Data Flow

- Parameters flow one way: parameter store over defaults registry into
  rendered service definitions, engine defaults, job configuration,
  and a target-side environment record consumed by the certificate
  generator.
- Certificate: environment record drives generation; the pair feeds
  the application, the runner trust stores, the engine trust store,
  and the control-machine copy. The private half never leaves the
  target.
- Backup: application data becomes one timestamped archive per run,
  moved to a backup store, oldest beyond retention deleted. Container
  registry blobs are excluded on purpose.
- Cleanup: the rendered service definitions define the protected image
  set; the engine inventory is compared against it; a first-seen
  record per unused item drives age-based deletion.
- Verification reads live state (listening sockets, HTTP status codes,
  in-container name resolution, file presence) and compares it to the
  parameter store. It never changes state.

## State Management

- Configuration state is declarative: definitions rendered from
  parameters; a rendered change restarts only the affected runtime.
- Create-once state, each guarded by an existence check and never
  regenerated in place: encryption key, certificate, admin account,
  runner registration.
- Ownership: the application owns its data volume; the runner owns its
  registration record; the backup worker owns the backup store; the
  cleanup worker owns the grace record; the certificate generator owns
  the certificate pair.
- Convergence state machine (generic):

  ```
  fresh install  -> preconditions pass -> create account (credentials
                   supplied) -> register runner -> converged
  converged      -> re-run -> existence checks skip creation ->
                   report no changes
  either         -> precondition or assertion fails -> abort with
                   cause and fix; no later area runs
  ```

## Contracts

- Entry points:
  - Full convergence run.
  - Verification-only run (no target changes).
  - Area-scoped runs (base, application, runner).
  - Operational-check run (opt-in; excluded from every other mode).
- Preconditions, validated before any change: target address is a
  valid IPv4 form; the expected network interface exists on the
  target; the session runs with full target privileges.
- Postconditions, asserted per area:
  - Base: the LAN name resolves to the LAN address on the target.
  - Application: the certificate is unexpired and names both the LAN
    address and the LAN name; the encryption key file exists; ports
    443, 80 and 2222 bind to the LAN address and nowhere else; HTTPS
    answers 200; plain HTTP answers a redirect to the canonical URL;
    the in-container name pin answers with the LAN address alone.
  - Runner: the in-container name pin answers correctly; the job
    configuration carries every mitigation marker; sample environment
    entries from the generator are absent.
  - Operational checks: a dump exists and contains no registry blob
    entries; the engine trusts the instance certificate; both
    schedules are armed.
- Error boundary: the run stops at the first fatal failure; every
  failure message states what failed, why, and what to do next.

## Persistence (abstract schemas)

- Data volume — owned by the container user identity: application
  database, repositories, LFS objects, generated configuration.
- Secrets store — the global data-encryption key; access-restricted;
  in no backup and not in version control; losing it permanently
  locks the encrypted values. Needs a backup of its own.
- Certificate store — private key (target-only) and public
  certificate (distributed); valid for years; regeneration re-arms
  every client pin.
- Backup store — timestamped archives; retention keeps exactly the N
  newest (N = 7 by default).
- Runner state — registration record and deployed job configuration;
  the configuration is always deployed from the repository, never
  regenerated on the target.
- Cleanup grace record — one row per unused item (identifier,
  first-seen-unused date); fully rewritten each run, so its size is
  bounded by the inventory on disk.
- Engine trust — a per-instance trust entry keyed by the instance
  name.

## External Dependencies

- Control machine: an isolated Python environment with the
  automation core and the linter; key-based access to the target.
- Target: Debian 13-class base with the openssl tool present;
  outbound internet for package and image fetches; a container engine
  with systemd integration; a multicast name responder announcing the
  LAN name; an operator-supplied resolver for containers.
- Pinned third-party images: the application and the runner, always
  by exact version, never a floating tag.
- Client devices: trust the public certificate once per device, after
  comparing its fingerprint.
- Admin credentials: supplied in the parameter store only for fresh
  installs; their absence means account creation and runner
  registration stay skipped.

## Non-Goals

- Restore: a documented manual file copy, not a playbook operation.
- Off-machine backup copies: the operator's responsibility.
- Mirroring third-party workflow actions: the operator maintains
  mirrors; the instance resolves action references to itself only.
- Gating workflows from fork pull requests: recommended, not
  configured.
