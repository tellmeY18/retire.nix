---
name: jujutsu
description: "**REQUIRED** - Always activate on any VCS operations. This repo uses Jujutsu (jj) — raw git commands can corrupt data. Essential jj workflow instructions inside. DO NOT IGNORE."
---

# Jujutsu (jj) Version Control System

This project uses **Jujutsu (jj)** as its VCS. The `.jj/` directory exists at the repo root. Raw `git` commands can corrupt jj state — use `jj` for everything.

**Remote:** `origin` → `git@github.com:tellmeY18/retire.nix`

**Exisiting bookmarks:** `main`, `develop`, `hm`, `feat/omniwm`, `neon-exp`

**Current `@`:** empty commit on top of `develop`.

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

3. **Verify with `jj st`** after mutations (`squash`, `abandon`, `rebase`, `restore`).

4. **Always use `jj diff --git`** — the default jj diff format uses side-by-side line numbers. `--git` gives standard unified diff with `+`/`-`.

## Core Concepts

### The Working Copy is a Commit

Your working directory is always a commit (`@`). Changes are auto-snapshotted. There is **no staging area** and **no need to run `jj commit`**.

### Change IDs vs Commit IDs

- **Change ID** (e.g. `tqpwlqmp`) — stable across rewrites; prefer these
- **Commit ID** (e.g. `3ccf7581`) — content hash, changes on rewrite

## Essential Workflow: Describe First, Then Code

**Always write your commit message before making changes:**

```bash
# Make sure you're on a clean revision first
jj st

# If @ already has content, create a new empty commit
jj new

# Describe what you're about to do
jj desc -m "Add user authentication to login endpoint"

# Make your changes — they auto-become part of this commit
# ... edit files ...

# Review
jj st
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
| Check status | `jj st` |
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

Move all changes from current commit into its parent:

```bash
jj squash
```

Do NOT use `jj squash -i` — it opens an interactive UI that hangs the agent.

### Splitting

Do NOT use `jj split` (interactive). Instead, use `jj restore` to move changes out, then create separate commits manually.

### Rebasing

```bash
# Rebase current branch onto a destination
jj rebase -d <destination>

# Rebase onto trunk (update your branch to latest main)
jj rebase -d main

# Rebase a specific revision onto a destination
jj rebase -r <change-id> -d main
```

## Bookmarks (Branches)

jj bookmarks are the equivalent of git branches. **They do NOT auto-advance** — you must update them explicitly.

```bash
# List bookmarks
jj --no-pager bookmark list

# Create a bookmark at current commit
jj bookmark create my-feature

# Move a bookmark to current commit
jj bookmark move my-branch --to @

# Delete a bookmark
jj bookmark delete my-branch
```

## Working with the Remote

```bash
# Fetch all branches from origin
jj git fetch

# Fetch from a specific remote
jj git fetch --remote origin

# Push a bookmark (creates/updates the corresponding git branch)
jj git push -b my-bookmark
```

### Before pushing

1. Ensure your bookmark points to the correct commit:
   ```bash
   jj bookmark move my-feature --to @
   ```

2. Ensure commits are atomic with clear messages.

### Typical sync cycle

```bash
# Get latest from remote
jj git fetch

# Rebase your work onto latest main
jj rebase -d main

# Push your bookmark
jj git push -b my-feature
```

## Handling Conflicts

jj allows committing conflicts. **Do not use `jj resolve`** (interactive). Instead:

1. Edit the conflicted files directly to remove conflict markers
2. Run `jj st` to verify resolution

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
jj st

# Can now use git
git <command>

# Switch back to jj
jj edit <change-id>
```

## Quick Reference

| Action | Command |
|--------|---------|
| Status | `jj st` |
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
| Push bookmark | `jj git push -b <name>` |
| Create bookmark | `jj bookmark create <name>` |
| Move bookmark | `jj bookmark move <name> --to <id>` |
| List bookmarks | `jj --no-pager bookmark list` |
