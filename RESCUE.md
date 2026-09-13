# Provenance of this branch

The upstream this add-on was forked to, `github.com/unsnow-iac/claude-code-ha`,
returned HTTP 404 as of 2026-09-13 — deleted or made private by an account we
don't control. No fork of it existed and it was not archived by Software
Heritage.

The only surviving copy was the Home Assistant Supervisor's own store clone at
`/data/apps/git/76aa35f0` inside the running `hassio_supervisor` container. That
clone was **shallow** — `.git/shallow` recorded 15 boundary commits, one per
tagged release the Supervisor had ever fetched, each with a full file tree but
no reachable parent commit. `git log` on it showed exactly one commit.

This branch (`unsnow-5.1.5`) reconstructs the release history from that shallow
clone by extracting each tag's tree via `git archive` and replaying the 11
releases (`v4.7.0` → `v5.1.5`, spanning 2026-07-02 to 2026-08-18) as a linear
sequence of commits:

- Each commit's **file tree and date are the genuine release contents and
  commit date** taken directly from the abandoned repo's tag objects.
- Each commit's **author/committer identity was preserved** as
  `unsnow-iac <256081678+unsnow-iac@users.noreply.github.com>` — this is a
  rescue, not a claim of authorship.
- What is **lost**: the original per-PR commit granularity between releases
  (the Supervisor only ever fetched one shallow commit per tag, not full
  history), and any commits between tags that never got a release.
- Verified before push: every tag's tree was scanned for private keys, API
  tokens, and credential-shaped filenames — none were found.

Merged to `main` as the current baseline for this fork going forward.

## Update 2026-09-13: the real history was recoverable after all

The "lost" per-PR granularity described above was not actually lost. A
shallow boundary commit still embeds its true parent SHA(s) in the raw
commit object — `git log` refuses to walk past the boundary, but
`git cat-file -p <sha>` reads the object directly and shows it. Every one of
those 15 boundary commits in the Supervisor's clone turned out to be a GitHub
merge commit with a second parent: the real PR-branch-head SHA that the
shallow fetch had never downloaded, but whose existence was still recorded in
the merge commit's own bytes.

Testing each newly-found SHA against `gh api repos/miczu71/claude-code-ha/commits/<sha>`
showed all of them resolve, courtesy of GitHub's fork-network object sharing
(this repo's network already includes `ESJavadex/claude-code-ha`, itself
forked from `heytcass/home-assistant-addons`). `git fetch origin <sha>` for
each one pulled in **its own full ancestry as well** — cascading all the way
back to the true genesis commit, `Initial 1.0.0 release of Claude Terminal
add-on` (2025-03-07, heytcass), with real per-PR granularity intact the
whole way: **198 genuine commits**, not the 11 synthesized above.

This means `main`'s history (the replay described above) is not an
approximation with gaps — it is a **parallel, synthetic graph**: the same
file tree and metadata as each real release, but fabricated linear
parentage. The genuine commits sat the entire time as unreferenced loose
objects, first in the Supervisor's own shallow clone, and reachable via
GitHub's network once any one of them was known.

The genuine graph is now preserved in this repository:

- Branch **`history/unsnow-full`** — the full 198-commit genuine chain, tip
  `0d648a9b` (the real "Merge pull request #36" commit for v5.1.5).
- Tags **`genuine/v4.7.0`** through **`genuine/v5.1.5`** — each existing
  release tag's true merge commit (distinct from the same-named tag already
  in this repo, which still points at the synthetic replay commit).

`main` was deliberately left untouched — re-rooting it onto the genuine
graph would rewrite every SHA and require a force-push, and this add-on's
own running instance updates from this repository's `main`, so that was kept
as a separate, explicit decision rather than folded into this fix. Anyone
who wants full authentic ancestry as the default branch can merge or rebase
onto `history/unsnow-full`.

What is still genuinely unrecoverable: nothing found so far. `legacy-2.0.x`
(the pre-v4.7.0 `v2.0.x` line) shares the same true genesis commit as the
198-commit graph but is its own divergent branch — already present in this
repo from before this recovery, not something this pass needed to touch.
