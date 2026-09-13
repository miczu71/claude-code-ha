# Claude Code add-on — post-migration verification & repair

## Context

The add-on that hosts this terminal was built from `github.com/unsnow-iac/claude-code-ha`,
which was **deleted** (HTTP 404, confirmed again today). An earlier session rescued the
source from the Supervisor's own **shallow** store clone, pushed it to
`github.com/miczu71/claude-code-ha`, and installed a **second, new add-on** from it.

You asked to verify that the migrated app works and that it has all the History.
Verification is complete — results below. It works, but five things are broken or
incomplete, and the genuine git history looks **recoverable** rather than lost.

### Verification results (read-only, already done)

**Confirmed working**
- Running add-on is the new one: `2c36418b_claude_terminal_unsnow` **v5.1.6**, repository
  `2c36418b` → `https://github.com/miczu71/claude-code-ha`, state `started`.
  (`hostname` = `2c36418b-claude-terminal-unsnow` — this session is inside it.)
- The Supervisor update pipeline **does** reach the add-on from its new home: it is on
  5.1.6 while the old add-on is pinned at 5.1.5. `build: true` means the Supervisor builds
  from the branch, so no GitHub Release is required for add-on updates.
- `/data` was migrated, not recreated: 676 MB `/data/home`, **135 session transcripts**,
  plans back to August, the memory dir, `.credentials.json`, and `options.json` identical
  to the old add-on (ha-mcp URL, `enable_ssh: true`, the authorized key).
- The self-updating Claude launcher from the earlier plan survived:
  `command -v claude` → `/data/packages/bin/claude`, running 2.1.270.
- Old add-on `76aa35f0_claude_terminal_unsnow` v5.1.5 is installed but **stopped** — no
  port-2222 or ingress conflict with the running one.

**Broken / incomplete**
1. `claude-terminal/build.yaml` label is still `5.1.5` while `config.yaml` is `5.1.6` →
   **CI red** on the migration commit (`Check version sync`).
2. Repo secret `BUMP_PAT` did not migrate → `auto-tag.yml` fails → **no `v5.1.6` tag**, so
   `release.yml` never fires and **no GitHub Release exists** for 5.1.6.
3. **Chromium is gone**: `/data/packages/bin/chromium{,-browser}` are dangling symlinks,
   `/data/packages/lib/chromium` is empty, `/usr/bin/chromium-browser` absent, and
   `persistent_apk_packages` is `[]`. `playwright-mcp-config.json` still points at
   `/usr/bin/chromium-browser` → the documented Playwright verification workflow fails.
4. **History is partial.** `main` has 13 commits: 11 release snapshots replayed from the
   shallow clone (`v4.7.0` 2026-07-02 → `v5.1.5` 2026-08-18) plus two rescue commits.
   Tags `v2.0.10`/`v2.0.11` and branch `legacy-2.0.x` survive separately. Missing: all
   per-PR commits between releases, and everything before `v4.7.0`.
   **Key finding:** GitHub **fork-network object sharing is live** — an ESJavadex-only SHA
   (`bd58430`) resolves inside `miczu71/claude-code-ha`. So the original `unsnow-iac`
   commit objects are plausibly still fetchable; what is missing is their **SHAs**, which
   still exist in the Supervisor's shallow clone for repo `76aa35f0`.
5. Docs still send users to the dead repo: `README.md:38` (install URL), `:141`, `:182`,
   `claude-terminal/DOCS.md` (×2), plus `build.yaml` `image.source`, both issue templates,
   `CODEOWNERS`, `SECURITY.md`. The Supervisor's own add-on description repeats it.

**Separate finding (outside the add-on):** `/config/.git/config` and
`/config/addons/nokia_tracker/.git/config` embed live `ghp_` tokens in plaintext remote URLs.

### Decisions taken

- Attempt **full history recovery**; old add-on and repo `76aa35f0` **stay installed** for
  now (its shallow clone is the only surviving source of the original SHAs — removing that
  store repo destroys it).
- Fix CI + publish 5.1.6, restore Chromium/Playwright, update docs, scrub the PATs.
- **De-brand from `unsnow`** — "it's our repo now".

---

## ⚠️ Two traps this plan deliberately avoids

**1. Do not change `slug:` in `claude-terminal/config.yaml`.**
The slug is `claude_terminal_unsnow`. The Supervisor keys an add-on's persistent `/data`
volume by full slug, so changing it does not rename the add-on — it creates a *third*
add-on with an **empty `/data`**: no OAuth credentials, no 135 transcripts, no plans, no
memory, no persistent packages, and a new ingress URL. That is the same migration you just
paid for, again. The slug is an internal identifier users never see; the sidebar shows
`panel_title`. **Recommendation: leave the slug alone.** Renaming it is listed as optional
Stage 7 and should only be done as a deliberate migration with a `/data` copy.

**2. Do not rewrite `main`'s ancestry in place.**
Grafting recovered history onto `main` changes every SHA and requires a force-push. The
Supervisor already holds a clone of `2c36418b` and pulls from it to update this add-on; a
non-fast-forward `main` risks breaking the very update channel we just proved works, on the
add-on we are running inside. So recovered history lands on a **dedicated branch plus
tags** — fully present and reachable in the repo — and `main` is left untouched unless you
explicitly ask for a single linear ancestry at the Stage 3 checkpoint.

**Kept on purpose (not "unsnow leftovers"):** the `Copyright (c) 2026 unsnow-iac` line in
`LICENSE` (MIT requires retaining copyright notices — the ESJavadex and heytcass lines stay
too), `RESCUE.md`'s provenance record, the `unsnow-iac` author identity on the rescued
commits, and historical `CHANGELOG.md` entries. Rewriting those would falsify authorship
and licence history. Everything forward-looking — URLs, maintainer, CODEOWNERS, issue
templates, CI commit identity — gets changed.

---

## Stages

Each stage stops at a checkpoint for review before the next one starts.
**First implementation step:** copy this file to `docs/MIGRATION-REPAIR.md` in
`miczu71/claude-code-ha` so the plan survives compaction.

### Stage 1 — Restore Chromium / Playwright (local, no repo changes)

Unblocks the verification tooling later stages need.

- Clear the two dangling symlinks in `/data/packages/bin/`.
- Add `chromium` to the add-on's `persistent_apk_packages` option via
  `ha_manage_app` (config mode) so it is reinstalled on every container recreation —
  this is the gap that made it vanish, and it is *not* migration damage.
- Install it now with `persist-install chromium` (per the `persistent-package-manager`
  skill — never bare `apk add`).
- Reconcile `~/.claude/playwright-mcp-config.json` `executablePath` with wherever
  `persist-install` actually lands the binary, and correct the `/usr/bin/chromium-browser`
  claim in `/config/CLAUDE.md` if it no longer holds.

**Verify:** `chromium-browser --version` prints a version; then a real Playwright MCP run —
screenshot the add-on's own ingress page to `/config/playwright/` **and** check
`browser_console_messages(error)`, per the standing self-review rule.

### Stage 2 — History recovery probe (read-only, no writes anywhere)

- Read the Supervisor's shallow clone for repo `76aa35f0`. It is not reachable from this
  add-on (`homeassistant` token, no `docker_api`), so it goes through the **Advanced SSH &
  Web Terminal** add-on, which already has `protected: false` and `docker_api: true`:
  `docker exec hassio_supervisor sh -c 'cd /data/addons/git/76aa35f0 && git cat-file --batch-check --batch-all-objects | grep commit'`
  plus `git rev-list --all` and the contents of `.git/shallow`.
  I will give you the exact command to paste with `!` if SSH from here doesn't authenticate.
- For each original commit SHA and each **parent** SHA recorded in those commit objects,
  test reachability in the new repo:
  `gh api repos/miczu71/claude-code-ha/commits/<sha>`.
- Produce a written reachability report: how far back the real chain resolves, whether it
  joins the ESJavadex root, and exactly what remains unrecoverable.

**Checkpoint:** go/no-go on Stage 3 based on what actually resolved. If nothing resolves,
Stage 3 is dropped and `RESCUE.md` stays the accurate record.

### Stage 3 — Land the recovered history

Only if Stage 2 found reachable objects.

- Fetch the recovered objects into a clone and push them as branch
  `history/unsnow-full` (name negotiable), plus any release tags that the real chain
  carries and the rescue could not reproduce.
- Update `RESCUE.md`: what was recovered, by what route, and what is still gone.
- **Optional, only on your explicit say-so at this checkpoint:** re-root `main` on the real
  chain. This is the force-push described in trap 2; if you want it, it gets its own
  verification that the Supervisor can still update the add-on afterwards.

**Verify:** `git log --oneline` on the new branch reaches back past `v4.7.0`;
`gh api .../commits?sha=history/unsnow-full` paginates the full chain; the add-on still
reports `update_available: false` at 5.1.6 (i.e. the store clone is undisturbed).

### Stage 4 — Fix CI and publish 5.1.6

- Bump `org.opencontainers.image.version` in `claude-terminal/build.yaml` to `5.1.6`
  (the CI `Check version sync` failure) and point `image.source` at the new repo.
- `BUMP_PAT`: you add a fine-grained PAT (Contents: Read/Write) as a repo secret so
  `auto-tag.yml` works for every future bump — I cannot create repo secrets for you.
  For 5.1.6 specifically, the recovery path already documented in `release.yml` works
  without it: push the `v5.1.6` tag manually, then `gh workflow run release.yml -f tag=v5.1.6`.
- Confirm the Release notes pick up the 5.1.6 `CHANGELOG.md` section; add one if missing.

**Verify:** `gh run list -R miczu71/claude-code-ha` shows CI green; `gh release list` shows
a **published** (not draft) `v5.1.6` — per the add-on release checklist.

### Stage 5 — De-brand the repo

Mechanical, with the exclusions in trap 2 respected. Files: `README.md`,
`claude-terminal/README.md`, `claude-terminal/DOCS.md`, `claude-terminal/config.yaml`
(description/url only — **not** `slug`), `claude-terminal/build.yaml`, `SECURITY.md`,
`.github/CODEOWNERS`, `.github/ISSUE_TEMPLATE/{config,bug_report}.yml`,
`.github/workflows/auto-tag.yml` (the `unsnow-iac` / `unsnow@pm.me` git identity).

Attribution becomes: maintained by **miczu71**, forked from ESJavadex ← heytcass, with the
`unsnow-iac` maintenance fork named as prior art rather than as the maintainer.

Per the CLAUDE.md editing rule, these are targeted `Edit` calls with previewed matches —
no bulk `sed` across YAML.

**Verify:** `grep -ril unsnow` returns only `LICENSE`, `RESCUE.md`, `CHANGELOG.md` history,
and `config.yaml`'s slug line. Then bump the add-on version, let the Supervisor update, and
confirm the **Supervisor's own add-on description** no longer advertises the dead URL —
that text comes from the repo, so it only changes after an update.

### Stage 6 — Scrub the leaked PATs

`/config/.git/config` and `/config/addons/nokia_tracker/.git/config` carry live `ghp_`
tokens in their remote URLs. Rewrite both remotes to token-free HTTPS and rely on the
already-authenticated `gh` CLI, then **revoke both tokens on GitHub** — a token that has sat
in a file is burned regardless of what we do to the file. Check the other add-on repos'
remotes at the same time.

**Verify:** `git -C <repo> remote -v` shows no credentials; `git fetch` still succeeds in
each repo; `gh auth status` still healthy.

### Stage 7 — Optional: rename the slug

Not recommended, listed only because you asked for the `unsnow` name to go. Requires
installing a third add-on from the renamed manifest, copying `/data` across, re-pointing the
sidebar, and re-doing the OAuth check — for a change no user ever sees. Decide at the end,
with Stages 1–6 already banked.

## Deferred

Decommissioning the old add-on `76aa35f0` and its dead store repository — your decision was
"keep for now", and Stage 2 depends on its clone. Worth revisiting once Stage 3 closes; it
would reclaim a duplicate `/data` and remove a dead-URL entry from the store.

## Standing constraints

- Never restart HA core; the add-on's own restarts still need your go-ahead since they drop
  this terminal session.
- Never rebuild the add-on locally — deploy is: bump version → published GitHub release /
  branch push → Supervisor update → verify via `ha_get_app`.
- Never uninstall the add-on or remove a store repository while it is the only source of
  something unrecovered.
