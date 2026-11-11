#!/usr/bin/env bash
# bump-version.sh — raise the repository version stored in VERSION.
# A missing VERSION file starts at 0.0.0, so the first `minor` bump
# yields 0.1.0. Writes the new version and prints it.
#
# Usage:
#   scripts/bump-version.sh patch   # 0.1.0 -> 0.1.1 (fixes)
#   scripts/bump-version.sh minor   # 0.1.0 -> 0.2.0 (features)
#   scripts/bump-version.sh major   # 0.1.0 -> 1.0.0 (breaking)
set -euo pipefail

cd "$(dirname "$0")/.."

BUMP="${1:-}"
case "$BUMP" in
patch | minor | major) ;;
*)
	echo "usage: scripts/bump-version.sh patch|minor|major" >&2
	exit 1
	;;
esac

current="0.0.0"
if [ -f VERSION ]; then
	current=$(tr -d '[:space:]' <VERSION)
fi
if [[ ! $current =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
	echo "VERSION does not hold X.Y.Z: '$current'" >&2
	exit 1
fi

major=${BASH_REMATCH[1]}
minor=${BASH_REMATCH[2]}
patch=${BASH_REMATCH[3]}
case "$BUMP" in
major)
	major=$((major + 1))
	minor=0
	patch=0
	;;
minor)
	minor=$((minor + 1))
	patch=0
	;;
patch) patch=$((patch + 1)) ;;
esac

echo "$major.$minor.$patch" >VERSION
echo "$major.$minor.$patch"
