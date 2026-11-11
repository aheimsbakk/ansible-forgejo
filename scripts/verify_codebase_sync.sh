#!/usr/bin/env bash
# verify_codebase_sync.sh — check that every repository file path listed
# in CODEBASE.md still exists on disk, and flag any listed path that is
# missing. Absolute paths describe target-side locations and are not
# checked; gitignored paths (parameter store, venv, fetched certs) are
# skipped because a fresh clone does not carry them.
#
# Usage (from anywhere):
#   scripts/verify_codebase_sync.sh              # checks CODEBASE.md
#   scripts/verify_codebase_sync.sh docs/OTHER.md  # checks another map
set -euo pipefail

cd "$(dirname "$0")/.."
CODEBASE="${1:-CODEBASE.md}"

if [ ! -f "$CODEBASE" ]; then
	echo "Could not find $CODEBASE; run this script from the repository root." >&2
	exit 1
fi

# Backticked tokens only; keep path-shaped ones (a slash or a file
# extension) and drop prose, flags, and placeholder-bearing names.
candidates=$(
	grep -o '`[^`]*`' "$CODEBASE" |
		tr -d '`' |
		grep -Ev '^/' |
		grep -E '^([A-Za-z0-9_.-]+/)+[A-Za-z0-9_.-]+$|^[A-Za-z0-9_.-]+\.[A-Za-z]+$' |
		sort -u
)

missing=0
checked=0
while IFS= read -r path; do
	[ -n "$path" ] || continue
	# Gitignored entries are deployment-time artifacts, not tracked files.
	if git rev-parse --git-dir >/dev/null 2>&1 && git check-ignore -q "$path"; then
		continue
	fi
	checked=$((checked + 1))
	if [ ! -e "$path" ]; then
		echo "MISSING: $path (listed in $CODEBASE)" >&2
		missing=$((missing + 1))
	fi
done <<<"$candidates"

if [ "$missing" -gt 0 ]; then
	echo "$missing listed path(s) missing, $checked checked. Update $CODEBASE or restore the files." >&2
	exit 1
fi
echo "OK: $checked listed path(s) exist."
