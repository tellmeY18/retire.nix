---
name: jujutsu
description: "**REQUIRED** - Always activate on any VCS operations. This repo uses Jujutsu (jj) — raw git commands can corrupt data. Essential jj workflow instructions inside. DO NOT IGNORE."
---

# Jujutsu (jj) Version Control System

This project uses **Jujutsu (jj)** as its VCS. The `.jj/` directory exists at the repo root. Raw `git` commands can corrupt jj state — use `jj` for everything.

**Remote:** `origin` → `git@github.com:tellmeY18/retire.nix`

**Current `@`:** clean working copy on latest trunk.

## Important: Agent Environment Rules

1. **Always use `--no-pager`** — prevents commands from opening `less`, which hangs the agent:

```bash
jj --no-pager log
jj --no-pager diff --git
jj --no-pager show <id>
jj --no-pager bookmark list
```

2. **Always use `-m` flags** for messages — avoids editor prompts that hang:

```bash
jj desc -m "message"
jj new -m "message"
```

3. **Verify with `jj --no-pager st`** after mutations (`squash`, `abandon`, `rebase`, `restore`).

4. **Always use `jj diff --git`** — the default jj diff format uses side-by-side line numbers. `--git` gives standard unified diff with `+`/`-`.

5. **On session start — create a fresh commit first.** Before any work, always run:
   ```bash
   jj new
   ```
   This ensures you start on an empty anonymous commit, avoiding accidental attachment to a previous session's changes.

## Core Concepts

### The Working Copy is a Commit

Your working directory is always a commit (`@`). Changes are auto-snapshotted. There is **no staging area** and **no need to run `jj commit`**.

### Change IDs vs Commit IDs

- **Change ID** (e.g. `tqpwlqmp`) — stable across rewrites; prefer these
- **Commit ID** (e.g. `3ccf7581`) — content hash, changes on rewrite

## Essential Workflow: Describe First, Then Code

**Always write your commit message before making changes.** This principle, combined with always starting from a clean commit, gives you full control over your change history.

### 1. Agent initiation — start fresh

Every new agent session begins with a clean empty commit. This is already enforced by the environment rules above (rule 5). Run `jj new` if it hasn't been done yet.

### 2. Describe, then code

```bash
# Verify you're on a clean revision
jj --no-pager st

# If @ already has content, create a new empty commit
jj new

# Describe what you're about to do
jj desc -m "Add user authentication to login endpoint"

# Make your changes — they auto-become part of this commit
# ... edit files ...

# Review
jj --no-pager st
jj --no-pager diff --git
```

### Commit message format

Use imperative verb phrase, sentence case, no full stop at the end:

```
Add user authentication to login endpoint
Fix null pointer in payment processor
Remove deprecated API endpoints
Update dependencies to latest versions
```

## Day-to-Day Commands

| Action | Command |
|--------|---------|
| Check status | `jj --no-pager st` |
| View log | `jj --no-pager log` |
| View diff | `jj --no-pager diff --git` |
| Show specific commit | `jj --no-pager show <change-id>` |
| New empty commit | `jj new` |
| New commit with message | `jj new -m "message"` |
| Edit existing commit | `jj edit <change-id>` |
| Edit parent commit | `jj prev -e` |
| Edit next commit | `jj next -e` |
| Squash changes into parent | `jj squash` |
| Auto-distribute to ancestors | `jj absorb` |
| Abandon commit | `jj abandon <change-id>` |
| Undo last operation | `jj undo` |
| Restore files (discard changes) | `jj restore [paths]` |
| Restore files from revision | `jj restore --from <change-id> [paths]` |

## Refining Commits

### Squashing

Squash folds the current commit's changes into its parent. **Before squashing, ensure you've created a fresh commit** so your working copy changes don't accidentally merge with the squash:

```bash
jj new          # isolate current working copy first
jj squash       # now squash the previous commit into its parent
```

Do NOT use `jj squash -i` — it opens an interactive UI that hangs the agent.

### Absorbing

Before running `jj absorb`, ensure you're on a fresh commit:

```bash
jj new          # isolate current working copy
jj absorb       # distribute staged-like changes into matching ancestors
```

### Splitting

Do NOT use `jj split` (interactive). Instead, use `jj restore` to move changes out, then create separate commits manually.

### Periodic commit hygiene

Occasionally clean up the local stack: before pushing, after a substantial session, or whenever one revision contains several unrelated concerns or many newly added files. Do not churn already-atomic revisions, and never rewrite commits reachable from a remote bookmark unless the user explicitly asks.

Group by logical concern, not merely by directory or file type. Keep each implementation with its tests, documentation, configuration, and encrypted secrets. Every changed path must appear in exactly one replacement revision.

Because `jj split` is interactive, rebuild a mixed local revision non-interactively:

```bash
# Inspect the mixed revision and recent stack.
jj --no-pager show <mixed> --git --stat
jj --no-pager log -r 'ancestors(@, 12)' --limit 12

# Start a replacement stack from the mixed revision's parent.
# Keep <mixed> reachable as the source until verification succeeds.
jj new <mixed-parent> -m "First logical change"
jj restore --from <mixed> path/to/first-group
jj --no-pager st

jj new -m "Second logical change"
jj restore --from <mixed> path/to/second-group
jj --no-pager st

# Repeat for every group, then prove no content was lost or added.
jj --no-pager diff --from <mixed> --to @ --git --stat
# The comparison above must report 0 files changed.

jj abandon <mixed>
jj --no-pager st
jj new
jj --no-pager st
```

If Jujutsu reports `Untracked paths` because files exceed `snapshot.max-new-file-size`, do not claim the tree is clean or silently ignore them. Inspect the files, then either commit them with an explicit per-command size override or ask whether they should be ignored. Never raise the repository limit permanently without the user's approval.

### Rebasing

```bash
# Rebase current commit onto a destination
jj rebase -d <destination>

# Rebase onto latest remote trunk
jj rebase -d main@origin

# Rebase a specific change onto a destination
jj rebase -r <change-id> -d main@origin
```

## Bookmarks (Branches)

Bookmarks are jj's bridge to git branches, but **this repo uses a bookmark-free workflow**. Local work is done with anonymous commits identified by change IDs, not branches.

Remote-tracking bookmarks (`main@origin`, `develop@origin`, etc.) are fetched automatically by `jj git fetch` and serve only as rebase targets. Do not create or move local bookmarks.

To inspect or clean up:
```bash
jj --no-pager bookmark list
jj bookmark delete <name>          # only if you accidentally created a local one
```

## Working with the Remote

GitHub hosts the canonical `develop` branch. Locally we stay bookmark-free — the remote `develop` is only touched momentarily at push time.

```bash
# Fetch latest from remote
jj git fetch

# Fetch from a specific remote
jj git fetch --remote origin
```

### Typical sync cycle (push to develop)

```bash
# 1. Rebase your work onto latest remote develop
jj rebase -d develop@origin

# 2. Point a local develop bookmark at your commit and push
jj bookmark set develop -r @
jj git push -b develop

# 3. Forget the local bookmark — remote develop stays intact
jj bookmark forget develop
```

### Before pushing

1. Confirm you're pushing the right commit:
   ```bash
   jj --no-pager log -r @
   ```

2. Ensure commits are atomic with clear messages.

## Handling Conflicts

jj allows committing conflicts. **Do not use `jj resolve`** (interactive). Instead:

1. Edit the conflicted files directly to remove conflict markers
2. Run `jj --no-pager st` to verify resolution

## Preserving Commit Quality

Before considering work done:

1. **Review**: `jj --no-pager show @` or `jj --no-pager diff --git`
2. **Atomic?** One logical change per commit
3. **Message clear?** Imperative verb phrase, no full stop
4. **Unrelated changes?** Use `jj restore` to move out, create separate commits
5. **Should changes be elsewhere?** `jj squash` or `jj absorb`

## Git Interop

This repo uses **colocated jj** (both `.jj/` and `.git/` exist). In non-colocated repos don't use git commands at all. Here it's safe but still prefer `jj`.

If you must use a raw git command (e.g. `jj` doesn't support a particular git feature):

```bash
# Ensure working copy is clean first
jj --no-pager st

# Can now use git
git <command>

# Switch back to jj
jj edit <change-id>
```

## Quick Reference

| Action | Command |
|--------|---------|
| Status | `jj --no-pager st` |
| Log | `jj --no-pager log` |
| Diff (git format) | `jj --no-pager diff --git` |
| Show commit | `jj --no-pager show <id>` |
| Describe (rename) | `jj desc -m "message"` |
| New commit | `jj new [-m "message"]` |
| Edit commit | `jj edit <id>` |
| Squash | `jj squash` |
| Absorb | `jj absorb` |
| Rebase | `jj rebase -d <dest>` |
| Abandon | `jj abandon <id>` |
| Undo | `jj undo` |
| Restore files | `jj restore [paths]` |
| Fetch remote | `jj git fetch` |
| Push change | `jj git push --change <change-id>` |
| List bookmarks | `jj --no-pager bookmark list` |
| Delete bookmark | `jj bookmark delete <name>` |
