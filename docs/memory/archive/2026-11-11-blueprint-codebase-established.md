---
topic: "Blueprint, codebase map, and docs split established"
importance: high
category: decision
tags: [blueprint, codebase, docs-split, sync-script]
created: 2026-11-11T17:59:48Z
model: kompis/qwen3.8-flash-next-iq3_s
---

BLUEPRINT.md (language-agnostic architecture) and CODEBASE.md (file map)
were created from the existing recipe on 2026-11-11. Run
`scripts/verify_codebase_sync.sh` after any file move; it skips absolute
target paths and gitignored entries. Developer content ("editing
configuration", development-notes pointer) moved from README.md to
CONTRIBUTING.md per the documentation-separation rule; README now holds
operator content only.
