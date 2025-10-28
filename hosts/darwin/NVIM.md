# NixVim Keybinds Cheatsheet

## What is `<leader>`?
By default in Neovim, `<leader>` is the `\` key (backslash). You press it before other keys.

---

## General Keybinds

| Keys | What It Does |
|------|-------------|
| `<Space> + e` | Opens/closes the file tree (NvimTree) |
| `<leader> + G` | Toggles GitHub Copilot suggestions on/off |

---

## Molten (Jupyter Notebooks)

| Keys | What It Does |
|------|-------------|
| `<leader> + m + i` | Start Molten (initialize kernel) |
| `<leader> + m + l` | Run the current line of code |
| `<leader> + m + e` | Run selected code (in visual mode) |
| `<leader> + m + r` | Re-run the current cell |

**How to use:**
1. Open a Python file
2. Press `\` then `m` then `i` to start Molten
3. Write some Python code
4. Press `\` then `m` then `l` to run the line your cursor is on

---

## Autocompletion (nvim-cmp)

| Keys | What It Does |
|------|-------------|
| `Tab` | Select next suggestion |
| `Shift + Tab` | Select previous suggestion |
| `Enter` | Accept the selected suggestion |

---

## Example Workflow

### Opening a file and running code:
1. Press `Space + e` to open the file tree
2. Navigate to your Python file and open it
3. Press `\ + m + i` to start Jupyter kernel
4. Write some code: `print("Hello")`
5. Press `\ + m + l` to run it

### Using Copilot:
1. Start typing code
2. Copilot will suggest completions automatically
3. Press `Tab` to see suggestions
4. Press `Enter` to accept
5. Press `\ + G` if you want to turn Copilot off

---

## Tips

- **`<leader>`** = `\` key (backslash)
- **`<Space>`** = Space bar
- Press keys in sequence, not all at once (e.g., for `<leader>mi`, press `\`, then `m`, then `i`)
- Most commands work in **normal mode** (press `Esc` to enter normal mode)
