#!/usr/bin/env bash
# Print the CHANGELOG section for one version, for use as GitHub Release notes.
#
# Shared by release.yml (the normal path) and auto-tag.yml (the fallback that
# publishes the Release itself if the tag-push trigger never fired). Both must
# produce byte-identical notes, so the extraction lives here once rather than
# being copy-pasted into two workflows that can drift apart.
#
# Usage: release-notes.sh <version> [changelog-file]
set -euo pipefail

version="${1:?usage: release-notes.sh <version> [changelog-file]}"
file="${2:-claude-terminal/CHANGELOG.md}"

if [ ! -f "$file" ]; then
    echo "release-notes.sh: no such changelog: $file" >&2
    exit 1
fi

# Print the block from "## <version>" up to (but not including) the next "## "
# version header. "### " subsection headers are kept.
notes=$(awk -v ver="$version" '
    $0 ~ "^## " ver "([[:space:]]|$)" { grab = 1; next }
    grab && /^## / { exit }
    grab { print }
' "$file")

# A version with no section is a release that would publish empty notes — treat
# it as an error so the caller fails loudly instead of shipping a blank Release.
if [ -z "$(printf '%s' "$notes" | tr -d '[:space:]')" ]; then
    echo "release-notes.sh: no CHANGELOG section found for $version in $file" >&2
    exit 1
fi

printf '%s\n' "$notes"
