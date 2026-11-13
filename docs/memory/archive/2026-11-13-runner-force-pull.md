---
topic: "Runner job images need force_pull enabled"
importance: high
category: warning
tags: [runner, ci, job-images, force-pull, trap]
created: 2026-11-13T23:40:00Z
model: kompis/qwen3.8-flash-next-iq3_s
---

The runner pulls a job image only when the tag is missing locally, so
`container.force_pull: false` in
`templates/runner-config.yaml.j2` leaves a re-pushed `latest` tag
serving its stale local copy — jobs run old code with no error and no
log. Keep the setting `true`. `tasks/runner.yml` asserts it, and the
per-job pull is what lets `cleanup.sh` delete unused job images safely.
Stack images (`forgejo_image`, `runner_image`) stay pinned by exact
version; the pull rule covers job images only. Details in
`docs/development-notes.md`, "Actions runner".
