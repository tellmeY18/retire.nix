# Emacs — Simple & Stupid Guide

## Where things live

| What | Path |
|------|------|
| Config source | `home/darwin/emacs/` in this repo |
| Runtime config | `~/.config/emacs/` → symlinked to repo (no rebuild needed) |
| Module loader | `init.el` — bootstraps MELPA, then loads everything in `lisp/` |
| UI / theme / scrolling | `lisp/ui.el` |
| Evil / leader | `lisp/evil.el` |
| Mode line | `lisp/modeline.el` |
| Completions | `lisp/completion.el` |
| LSP / major modes | `lisp/ide.el` |
| Terminal | `lisp/ghostel.el` |
| Markdown | `lisp/markdown.el` |
| Keybindings | `lisp/keybindings.el` |
| Workspaces | `lisp/workspace.el` |
| Packages | `init.el` — add/remove `use-package` lines for MELPA packages |
| Cache | `~/.cache/emacs/` |
| State (recentf, savehist, custom.el) | `~/.local/state/emacs/` |

## Iterating

Edit any `.el` file in `home/darwin/emacs/` and restart Emacs (or `M-x eval-buffer`).
No `nh darwin rebuild` needed — config is live from the repo.

## Opening

```sh
emacs-gui        # GUI app (Dock icon, proper macOS app)
emacs            # terminal (runs inside your current terminal)
emacsclient -t   # faster: connects to a running Emacs daemon
emacsclient -c   # GUI frame from terminal
```

## It's Vim Now

Evil is on by default. You get `hjkl`, modes, `:w`, `:q`, `dd`, `yy`, `p`, `u`/`C-r`, the works.

| What | Key |
|------|-----|
| Go back to Normal | `<Esc>` in insert/visual |
| Quit something (minibuffer, completion) | `<Esc>` |
| Undo | `u` |
| Redo | `C-r` |

## The Leader Key = Space

`<Space>` in normal/visual mode opens the leader menu. Which-key shows you everything. Common ones:

| Key | Does What |
|-----|-----------|
| `<Space> f` | Find file anywhere (fd) |
| `<Space> e` | Toggle file tree (neotree) |
| `<Space><Space>` | Find file in current project |
| `<Space> b b` | Switch buffer (no special buffers) |
| `<Space> b B` | Switch buffer (including special buffers) |
| `<Space> g p` | Search in project (ripgrep) |
| `<Space> g l` | Search current buffer (consult-line) |
| `<Space> d` | List diagnostics |
| `<Space> s` | Jump to symbol in file (imenu) |
| `<Space> S` | Jump to LSP symbol across project |
| `<Space> G G` | Magit status |
| `<Space> G c` | Magit log for current file |
| `<Space> c a` | LSP code actions |
| `<Space> c r` | LSP rename |
| `<Space> x d` | Show buffer diagnostics |
| `<Space> x n/p` | Next/prev error |

Start typing after `<Space>` and which-key will show you everything.

## Workspaces (Tab Bar)

Emacs starts with three named tab-bar workspaces — **ohc** (ohcnetwork), **10b** (10bedicu), and **jira** (Jira MCP server with a ghostel terminal). Each workspace tracks its own window layout, buffer list, and project root.

| Key | What |
|-----|------|
| `<Space> 1-9` | Switch to tab by number |
| `<Space> [` / `<Space> ]` | Previous / next tab |
| `<Space> t n` | New tab |
| `<Space> t k` | Close current tab |
| `M-x my/workspace-ohc` | Jump/create ohc workspace |
| `M-x my/workspace-10b` | Jump/create 10b workspace |
| `M-x my/workspace-jira` | Jump/create jira workspace (with terminal) |

Use `<Space><Space>` (`project-find-file`) within a workspace to browse files relative to that workspace's project root. `tab-bar-history-mode` is on — `C-x <left>`/`C-x <right>` navigates tab history.

## File Tree (Neotree)

| In neotree | What |
|------------|------|
| `o` / `RET` | Open file |
| `s` | Open in vertical split |
| `S` | Open in horizontal split |
| `g` | Refresh |
| `R` | Rename |
| `c` | Create |
| `d` | Delete |
| `q` | Hide |
| `H` | Toggle hidden files |

## Completions (Corfu + Vertico)

- **In-buffer completions**: popup appears automatically after 2 chars (Corfu). `TAB` / `S-TAB` to cycle, `RET` to pick.
- **Everywhere else** (M-x, switch buffer, find file): vertical list (Vertico). Type to narrow, `C-n`/`C-p` or arrows to move. `RET` to select.
- **Orderless**: type space-separated parts in any order — `foo bar` matches anything containing both.
- **`C-M-i`**: manually trigger completion.
- **`C-h`** after a command shows help in a tooltip (eldoc-box).
- **`C-x C-f`**: file finder (orderless search with `M-r` for history).

## LSP (eglot)

LSP starts automatically when you open supported files (Rust, TypeScript, Go, Python, Nix, Elixir, JSON, YAML, Dockerfile, Bash, QML).

| In a file | What |
|-----------|------|
| `K` | Help at point (hover docs) |
| `gd` | Go to definition |
| `gr` | Find references |
| `gi` | Go to implementation |
| `gt` | Go to type definition |
| `<Space> c a` | Code actions |
| `<Space> c r` | Rename across project |

## Ghostel (Terminal Inside Emacs)

Opens a real zsh in a buffer. Not a terminal emulator — a pseudo-terminal with Emacs integration.

| Key (insert mode) | What |
|-------------------|------|
| `C-t` | New terminal tab |
| `C-<Tab>` | Next tab |
| `C-S-<Tab>` | Previous tab |
| `C-S-v` | Paste clipboard |
| `C-c` | Send Ctrl-C |
| `C-<Esc>` | Back to normal mode |
| `C-x` | Send Ctrl-X |

| Key (normal mode) | What |
|-------------------|------|
| `C-t` | New terminal tab |
| `RET` | Open file path at cursor |
| `]l` / `[l` | Next/prev hyperlink |
| `o` etc. | Normal Vim motion in scroll-back |

### Shell commands for files

Inside a ghostel terminal, use these to open files in Emacs:

```sh
e  <file>     # open file (replaces current window)
es <file>     # open file in a horizontal split
ev <file>     # open file in a vertical split
```

## Text size

| Key | What |
|-----|------|
| `C-+` | Bigger text |
| `C--` | Smaller text |
| `C-=` | Reset text size |

## Markdown

- `.md` files open in GFM mode automatically.
- **WYSIWYG**: markup hides in normal mode, shows when you start typing.
- Code blocks are fontified.
- `visual-line-mode` is on (word wrap at window edge).

## Theme

Kanagawa Wave. If you want to change it, edit the `load-theme` line in `ui.el`.

## Other Bits

- `C-x C-f` — open file
- `C-x C-s` — save
- `C-x b` — switch buffer (with Vertico preview)
- `C-x k` — kill buffer
- `C-x C-c` — quit Emacs
- `M-x` — run any command (Vertico + orderless fuzzy search)
- `M-x global-text-scale-adjust` — another way to resize text
- `M-x my/change-major-mode` — switch language mode
