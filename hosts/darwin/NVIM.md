# Satanic Vim — Keybinds Cheatsheet

```
 ███████╗ █████╗ ████████╗ █████╗ ███╗   ██╗██╗ ██████╗    ██╗   ██╗██╗███╗   ███╗
 ██╔════╝██╔══██╗╚══██╔══╝██╔══██╗████╗  ██║██║██╔════╝    ██║   ██║██║████╗ ████║
 ███████╗███████║   ██║   ███████║██╔██╗ ██║██║██║         ██║   ██║██║██╔████╔██║
 ╚════██║██╔══██║   ██║   ██╔══██║██║╚██╗██║██║██║         ╚██╗ ██╔╝██║██║╚██╔╝██║
 ███████║██║  ██║   ██║   ██║  ██║██║ ╚████║██║╚██████╗     ╚████╔╝ ██║██║ ╚═╝ ██║
 ╚══════╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝ ╚═════╝     ╚═══╝  ╚═╝╚═╝     ╚═╝
```

**Satanic Vim** — FreeBSD devil-inspired dark Neovim configuration.
`<leader>` = `Space`

---

## Legend

| Symbol | Meaning |
|--------|---------|
| `<leader>` | Space bar |
| `C-` | Control |
| `M-` | Alt/Option |
| `S-` | Shift |
| `[n]` | Normal mode |
| `[i]` | Insert mode |
| `[v]` | Visual mode |
| `[x]` | Select mode |

---

## Opening Satanic Vim

`<leader>` groups | What you see when you press Space

| Group | Icon | Description |
|-------|------|-------------|
| `f` | `` | Find (Telescope) |
| `g` | `` | Git |
| `l` | `` | LSP |
| `t` | `` | Tab / Terminal |
| `h` | `` | Harpoon |
| `x` | `` | Trouble / Diagnostics |
| `m` | `` | Molten / Maximize |
| `n` | `` | Test |

---

## General

| Keys | What It Does |
|------|-------------|
| `jk` / `kj` | Exit insert mode |
| `C-s` | Save file |
| `<leader>w` | Save file |
| `<leader>q` | Quit |
| `<leader>Q` | Force quit |
| `<leader>wq` | Save and quit |
| `<leader>W` | Sudo write (`w !sudo tee %`) |
| `<leader>nh` | Clear search highlights |
| `<leader>v` | Edit init.lua |
| `<leader>V` | Edit nixvim config dir |

---

## Window Navigation

| Keys | What It Does |
|------|-------------|
| `C-h` | Go to left window |
| `C-j` | Go to lower window |
| `C-k` | Go to upper window |
| `C-l` | Go to right window |

---

## Window Management

| Keys | What It Does |
|------|-------------|
| `<leader>sv` | Split vertically |
| `<leader>sh` | Split horizontally |
| `<leader>se` | Equalize splits |
| `<leader>sx` | Close current split |
| `<leader>sm` | Maximize / restore split (`vim-maximizer`) |

---

## Tab Management

| Keys | What It Does |
|------|-------------|
| `<leader>tn` | New tab |
| `<leader>tc` | Close tab |
| `<leader>to` | Close other tabs |
| `<leader>t[` | Previous tab |
| `<leader>t]` | Next tab |

---

## Buffer Navigation

| Keys | What It Does |
|------|-------------|
| `<leader>bd` | Delete buffer |
| `<leader>bD` | Force delete buffer |
| `<leader>bn` | Next buffer |
| `<leader>bp` | Previous buffer |

---

## File Navigation (Telescope)

| Keys | What It Does |
|------|-------------|
| `<leader>ff` | Find files |
| `<leader>fg` | Live grep (search in files) |
| `<leader>fb` | Find buffers |
| `<leader>fh` | Find help tags |
| `<leader>fr` | Recent files |
| `<leader>fk` | Find keymaps |
| `<leader>fc` | Find commands |
| `<leader>fs` | Spell suggest |
| `<leader>ft` | Find TODO comments |
| `<leader>fT` | TODO trouble list |
| `<leader>e` | Toggle file tree (NvimTree) |
| `<leader>E` | Focus file tree |

---

## Harpoon (Quick File Marks)

| Keys | What It Does |
|------|-------------|
| `<leader>ha` | Add current file to harpoon |
| `<leader>hh` | Toggle harpoon quick menu |
| `<leader>h1` | Go to harpoon file 1 |
| `<leader>h2` | Go to harpoon file 2 |
| `<leader>h3` | Go to harpoon file 3 |
| `<leader>h4` | Go to harpoon file 4 |

---

## Flash Search (Enhanced Motions)

| Keys | What It Does |
|------|-------------|
| `s` | Flash jump — type 2 chars, then jump to label |
| `S` | Flash treesitter — jump to visible AST nodes |

**How to use:** In normal mode press `s`, then type 2 characters you want to jump to. Labels appear; press the label key to jump.

---

## LSP (Language Server Protocol)

| Keys | What It Does |
|------|-------------|
| `gd` | Go to declaration |
| `gD` | Go to definition |
| `K` | Hover documentation |
| `gi` | Go to implementation |
| `gr` | Go to references |
| `gt` | Go to type definition |
| `<leader>ca` | Code action |
| `<leader>rn` | Rename symbol |
| `<leader>ld` | Line diagnostics (float) |
| `[d` | Previous diagnostic |
| `]d` | Next diagnostic |
| `<leader>lq` | Send diagnostics to loclist |
| `<leader>li` | LSP info |
| `<leader>ll` | LSP log |

---

## Trouble (Diagnostics List)

| Keys | What It Does |
|------|-------------|
| `<leader>xx` | Toggle diagnostics list |
| `<leader>xw` | Workspace diagnostics |
| `<leader>xd` | Document diagnostics |
| `<leader>xq` | Quickfix list |
| `<leader>xl` | Location list |
| `<leader>xr` | LSP references |

---

## Git

| Keys | What It Does |
|------|-------------|
| `<leader>gg` | Neogit status (Magit-like interface) |
| `<leader>gd` | Diffview open |
| `<leader>gD` | Diffview close |
| `<leader>gh` | File history |
| `<leader>gc` | Git commit |
| `<leader>gp` | Git push |
| `<leader>hs` | Stage hunk |
| `<leader>hr` | Reset hunk |
| `<leader>hS` | Stage buffer |
| `<leader>hu` | Undo stage hunk |
| `<leader>hR` | Reset buffer |
| `<leader>hp` | Preview hunk |
| `<leader>hb` | Blame line |
| `<leader>hd` | Diff this |
| `<leader>hD` | Diff this `~` |
| `<leader>ht` | Toggle blame |
| `<leader>hT` | Toggle signs |
| `]c` | Next hunk |
| `[c` | Prev hunk |

---

## Terminal (ToggleTerm)

| Keys | What It Does |
|------|-------------|
| `<leader>tt` | Toggle terminal (horizontal) |
| `<leader>tf` | Float terminal |
| `<leader>tv` | Vertical terminal |
*(Inside terminal: `exit` or `C-d` to close)*

---

## Quickfix List

| Keys | What It Does |
|------|-------------|
| `<leader>cn` | Next quickfix item |
| `<leader>cp` | Prev quickfix item |
| `<leader>co` | Open quickfix list |
| `<leader>cc` | Close quickfix list |

---

## Neotest (Test Runner)

| Keys | What It Does |
|------|-------------|
| `<leader>nn` | Run nearest test |
| `<leader>nf` | Run test file |
| `<leader>nl` | Run last test |
| `<leader>ns` | Toggle test summary |
| `<leader>no` | Toggle test output |

---

## Molten (Jupyter Notebooks)

| Keys | What It Does |
|------|-------------|
| `<leader>mi` | Initialize Molten (start kernel) |
| `<leader>ml` | Run current line |
| `<leader>mr` | Re-evaluate cell |
| `<leader>me` | Evaluate operator |
| `<leader>mv` | Evaluate visual selection |

**How to use:**
1. Open a Python file
2. Press `Space` then `m` then `i` to start Molten
3. Write some Python code
4. Press `Space` then `m` then `l` to run the line

---

## Utils

| Keys | What It Does |
|------|-------------|
| `<leader>u` | Toggle undotree (visual undo history) |
| `<leader>G` | Toggle GitHub Copilot on/off |
| `<leader>y` | Yank to system clipboard (visual) |
| `<leader>p` | Paste from system clipboard |
| `<leader>d` | Delete to void register (don't yank) |

---

## Treesitter Text Objects

| Keys | What It Does |
|------|-------------|
| `af` | Around function |
| `if` | Inside function |
| `ac` | Around class |
| `ic` | Inside class |
| `ap` | Around parameter |
| `ip` | Inside parameter |
| `]]` | Next function start |
| `[[` | Previous function start |

---

## Autocompletion (nvim-cmp)

| Keys | What It Does |
|------|-------------|
| `Tab` | Select next / expand snippet |
| `S-Tab` | Select previous / jump back |
| `Enter` | Accept suggestion |
| `C-Space` | Force complete |
| `C-d` | Scroll docs down |
| `C-u` | Scroll docs up |
| `C-e` | Abort |

---

## Git Signs (Inline Blame)

Gitsigns shows inline blame at the end of the current line:
```
    Author, 2024-01-15  •  commit summary
```
Toggle it with `<leader>ht`.

---

## Which-Key

Press `<leader>` (Space) and wait a moment — a popup shows available keybindings grouped by category. Press the group key to drill down.

---

## Tips

- `<leader>` = Space bar
- Press `jk` in insert mode to escape
- Use `s` to jump anywhere visible with 2 characters
- `<leader>gg` opens Neogit — press `?` inside Neogit for its keybindings
- `<leader>tt` opens a terminal from inside Neovim
- `C-h/j/k/l` navigates between splits without `<leader>`
- In Telescope, `C-j/k` to move, `Enter` to select, `C-n/p` for history
- `<leader>G` toggles Copilot on/off (`C-G` was already taken by Molten)
