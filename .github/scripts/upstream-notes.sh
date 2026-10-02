#!/usr/bin/env bash
# Print Anthropic's own release notes for a Claude Code version bump, ready to
# paste under the add-on's CHANGELOG entry.
#
# Used by claude-version-bump.yml. The source is anthropics/claude-code's
# CHANGELOG.md — the same file https://code.claude.com/docs/en/changelog is
# generated from — newest first, one "## <version>" section per release.
#
# Prints every section after <current> up to and including <latest>, because the
# bump can skip versions (e.g. 2.1.280 -> 2.1.283). The "## " headers are demoted
# to "#### Claude Code <version>": release-notes.sh cuts the add-on CHANGELOG on
# "## ", so an upstream "## " header would end the add-on's section early.
#
# Never fails the bump: if the upstream file can't be fetched or has no section
# for <latest> yet (npm can publish before the changelog commit lands), it prints
# just a link to the docs page.
#
# Usage: upstream-notes.sh <current> <latest> [upstream-changelog-file]
set -euo pipefail

current="${1:?usage: upstream-notes.sh <current> <latest> [file]}"
latest="${2:?usage: upstream-notes.sh <current> <latest> [file]}"
file="${3:-}"

docs_url="https://code.claude.com/docs/en/changelog"
raw_url="https://raw.githubusercontent.com/anthropics/claude-code/main/CHANGELOG.md"

if [ -z "$file" ]; then
    file=$(mktemp)
    trap 'rm -f "$file"' EXIT
    curl -fsSL --max-time 30 "$raw_url" -o "$file" || : > "$file"
fi

# From "## <latest>" up to (not including) "## <current>". The line cap is a
# backstop in case <current> is missing upstream, so we never paste the whole
# history. Versions are matched literally (dots are not regex wildcards).
notes=$(awk -v lat="$latest" -v cur="$current" '
    /^## / {
        v = $2
        if (v == cur) exit
        if (v == lat) grab = 1
        if (grab) { print "#### Claude Code " v; n++; next }
    }
    grab { print; if (++n >= 400) exit }
' "$file")

if [ -z "$(printf '%s' "$notes" | tr -d '[:space:]')" ]; then
    printf 'Upstream release notes: %s\n' "$docs_url"
    exit 0
fi

# $(...) already dropped the trailing blank lines of the last section.
printf '%s\n\nSource: %s\n' "$notes" "$docs_url"
