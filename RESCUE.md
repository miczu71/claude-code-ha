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
