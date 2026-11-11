#!/usr/bin/env bash
# validate-changelog.sh — check that CHANGELOG.md follows the project's
# changelog format: one "# Changelog" title, version headers of the form
# "## [X.Y.Z] - YYYY-MM-DD", the why/model/tags metadata lines directly
# after each version header, and only the five known category headings.
#
# Usage:
#   scripts/validate-changelog.sh            # checks CHANGELOG.md
#   scripts/validate-changelog.sh path/to.md
set -euo pipefail

cd "$(dirname "$0")/.."
CHANGELOG="${1:-CHANGELOG.md}"

if [ ! -f "$CHANGELOG" ]; then
	echo "Could not find $CHANGELOG; run this script from the repository root." >&2
	exit 1
fi

problems=0
report() {
	echo "CHANGELOG: $1" >&2
	problems=$((problems + 1))
}

grep -qx '# Changelog' "$CHANGELOG" || report "missing '# Changelog' title"
grep -Eq '^## \[' "$CHANGELOG" || report "no version headers (## [X.Y.Z] - date)"

version_re='^## \[[0-9]+\.[0-9]+\.[0-9]+\] - [0-9]{4}-[0-9]{2}-[0-9]{2}$'
while IFS= read -r line; do
	if [[ ! $line =~ $version_re ]]; then
		report "bad version header: $line"
	fi
done < <(grep -E '^## ' "$CHANGELOG")

while IFS= read -r line; do
	category=${line#'### '}
	case "$category" in
	Added | Changed | Fixed | Removed | Security) ;;
	*) report "unknown category heading: $line" ;;
	esac
done < <(grep -E '^### ' "$CHANGELOG")

# Each version header must be followed (after blank lines) by exactly
# the why, model, and tags metadata lines.
while IFS= read -r header; do
	block=$(grep -A4 -F -- "$header" "$CHANGELOG")
	if [[ $block != *'- **why:**'* || $block != *'- **model:**'* || $block != *'- **tags:**'* ]]; then
		report "version entry missing why/model/tags metadata: $header"
	fi
done < <(grep -E '^## \[' "$CHANGELOG")

if [ "$problems" -gt 0 ]; then
	echo "$problems problem(s) in $CHANGELOG" >&2
	exit 1
fi
echo "OK: $CHANGELOG follows the changelog format."
