# Emacs — Lessons from Zero

## Lesson 0: Open and Close

```sh
emacs-gui    # GUI app with a Dock icon
emacs        # terminal mode (inside your current terminal)
```

To quit: `C-x C-c` or `:x` then Enter.

When Emacs opens, you see a terminal (ghostel). That's normal. You live in the shell.

---

## Lesson 1: It's Just Vim

Evil gives you Vim inside Emacs. The mode-line has a tag at the very left:

```
NORMAL | INSERT | VISUAL
```

| Do this | Key |
|---------|-----|
| Go to normal mode | `<Esc>` |
| Go to insert mode | `i` |
| Move around | `h j k l` |
| Save | `:w` Enter |
| Quit | `:q` Enter |
| Save and quit | `:wq` Enter |
| Undo | `u` |
| Redo | `C-r` |
| Delete a line | `dd` |
| Copy a line | `yy` |
| Paste | `p` |
| Visual select | `v` then move, then `d`/`y`/etc. |
| Find file | `:e <file>` Enter |

That's it. If you know Vim, you know 90% of Emacs now.

---

## Lesson 2: The Terminal (Ghostel)

When Emacs starts, it opens a ghostel terminal in the current window. It's a real zsh. You can do anything you'd do in a terminal.

**Inside the terminal (insert mode — you're typing shell commands):**

| Key | What |
|-----|------|
| `C-<Esc>` | Leave the terminal. Now you're in normal mode (browsing). |
| `C-t` | Open a fresh terminal right here |
| `C-<Tab>` | Switch to the next terminal buffer |
| `C-S-<Tab>` | Switch to the previous terminal buffer |
| `C-S-v` | Paste from system clipboard |
| `C-c` | Send Ctrl-C (interrupt) |

**Inside the terminal (normal mode — browsing scrollback):**

| Key | What |
|-----|------|
| `j`/`k` | Scroll up/down in terminal history |
| `C-t` | Open a fresh terminal |
| `RET` | Open the file path under cursor in Emacs |
| `]l` / `[l` | Next / previous hyperlink in terminal output |

**Open files from the shell:**

```sh
e  main.rs      # open file (replaces the terminal window)
es main.rs      # open file in a horizontal split (terminal stays)
ev main.rs      # open file in a vertical split
```

---

## Lesson 3: The Leader Key — It's Space

Press `<Space>` in normal mode. A menu pops up (which-key). Keep typing to see more.

The most useful ones:

| Keys | What |
|------|------|
| `SPC f` | Find any file (`fd`) |
| `SPC SPC` | Find file in the current project |
| `SPC b b` | Switch to another buffer (ignores \*scratch\*-type buffers) |
| `SPC b B` | Switch buffer (shows *everything*) |
| `SPC g p` | Search text in project (`ripgrep`) |
| `SPC g l` | Search text in the current file |
| `SPC e` | Toggle the file tree sidebar (neotree) |

Type `SPC` and wait half a second — which-key shows you the full menu.

---

## Lesson 4: Windows, Splits, and Terminals

You can have terminals and files side by side.

**New frames (real OS windows):**

| Keys | What |
|------|------|
| `SPC w n` | New frame — another OS window into the same Emacs session |
| `SPC w d` | Delete the current frame |
| `SPC w o` | Go to the other frame |

**Splits (panes inside a frame):**

| Keys | What |
|------|------|
| `SPC t s` | Split window horizontally (top/bottom) and open a terminal in the new pane |
| `SPC t v` | Split window vertically (left/right) and open a terminal in the new pane |
| `SPC t t` | Replace the current window with a terminal |

**Move between windows (panes):** Use the mouse, or:

- `C-w h/j/k/l` — Vim-style window navigation (left/down/up/right)
- `C-w w` — cycle windows

**Resize windows:**

| Keys | What |
|------|------|
| `C-w =` | Balance window sizes |
| `C-w -` / `C-w +` | Shrink / grow height |
| `C-w <` / `C-w >` | Shrink / grow width |

**Close window / split:**

| Keys | What |
|------|------|
| `C-w c` | Close the current window (keep the buffer alive) |
| `C-w o` | Keep only the current window (close all others) |

---

## Lesson 5: Code Editing (LSP)

When you open a code file (Rust, TS, Go, Python, Nix, Elixir, etc.), Eglot starts a language server automatically. You get:

| Key | What |
|-----|------|
| `K` | Hover — show docs for the thing under cursor |
| `gd` | Go to definition |
| `gr` | Find all references |
| `gi` | Go to implementation |
| `gt` | Go to type definition |
| `SPC c a` | Code actions (auto-fix, refactor, etc.) |
| `SPC c r` | Rename the symbol everywhere in the project |
| `SPC S` | Search symbols across the whole project |
| `SPC s` | Search symbols in the current file |
| `SPC x n` / `SPC x p` | Next / previous error (flymake) |
| `SPC d` | List all diagnostics |

---

## Lesson 6: Git (Magit)

`SPC G G` opens Magit status — the best Git UI that exists.

From the Magit status buffer:

| Key | What |
|-----|------|
| `s` | Stage the file under cursor |
| `S` | Stage everything |
| `c c` | Create a commit (write message, `C-c C-c` to confirm) |
| `P P` | Push to remote |
| `F F` | Pull from remote |
| `b b` | Switch branch |
| `l l` | Show log |
| `f f` | Show log for current file |

Other git keys from normal mode:

| Keys | What |
|------|------|
| `SPC G G` | Magit status |
| `SPC G c` | Magit log for the current file |
| `SPC G do` | Diff working tree |
| `SPC G dc` | Bury magit buffer |

---

## Lesson 7: The File Tree (Neotree)

`SPC e` toggles the file tree sidebar.

| In the tree | What |
|-------------|------|
| `o` / `RET` | Open file |
| `s` | Open in vertical split |
| `S` | Open in horizontal split |
| `g` | Refresh |
| `R` | Rename file |
| `c` | Create file |
| `d` | Delete file |
| `q` | Hide the tree |
| `H` | Toggle hidden files |

---

## Lesson 8: Completions

There are two completion systems:

**In-buffer (Corfu):** As you type, a popup appears. `TAB` / `S-TAB` to cycle, `RET` to pick.

**Everywhere else (Vertico):** `M-x`, `SPC b b`, `SPC f` — a vertical list appears. Type to narrow. `C-n`/`C-p` to move. `RET` to select.

**Orderless:** You can type words in any order. `log err` matches anything with both "log" and "err".

---

## Lesson 9: Text Size and Markdown

**Zoom:**

| Key | What |
|-----|------|
| `C-+` | Bigger text |
| `C--` | Smaller text |
| `C-=` | Reset to default size |

**Markdown:** `.md` files open in GFM mode. Markup hides in normal mode (WYSIWYG) and shows when you start typing. Word wrap is on.

---

## Lesson 10: Where Things Live

| What | Path |
|------|------|
| Config directory | `packages/emacs/emacs.d/` in this repo |
| Module loader | `init.el` — loads everything in `lisp/` |
| UI / theme / scrolling | `lisp/ui.el` |
| Evil / Vim keybindings | `lisp/evil.el` |
| Mode line | `lisp/modeline.el` |
| Completions | `lisp/completion.el` |
| LSP / language modes | `lisp/ide.el` |
| Terminal integration | `lisp/ghostel.el` |
| Markdown | `lisp/markdown.el` |
| Keybindings | `lisp/keybindings.el` |
| Package list | `default.nix` — add/remove MELPA packages here |
| Cache | `~/.cache/emacs/` |
| State (recent files, history, custom.el) | `~/.local/state/emacs/` |

To add a package: add it to the `emacsPkgs.melpaPackages` list in `packages/emacs/default.nix`, then rebuild.
