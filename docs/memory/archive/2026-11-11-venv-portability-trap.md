---
topic: "Checked-out .venv has machine-local interpreter paths"
importance: medium
category: warning
tags: [venv, uv, control-environment, trap]
created: 2026-11-11T19:05:04Z
model: kompis/qwen3.8-flash-next-iq3_s
---

A `.venv` created by uv on one machine fails on another: script
shebangs and `pyvenv.cfg` point at the original host's absolute Python
paths. Fix is `rm -rf .venv` then the README quick-start uv commands.
`.venv/` is gitignored, so this only bites when a venv was copied
outside git.
