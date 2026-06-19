# OmniWM Quick Reference

OmniWM is a macOS tiling window manager with two layout engines: **Niri** (scrolling columns) and **Dwindle** (BSP tree). This cheatsheet covers the default keybindings.

> **Modifier legend:** `Cmd` = ⌘ Command, `Opt` = ⌥ Option, `Ctrl` = ⌃ Control, `Shift` = ⇧ Shift

---

## Workspaces

| Action | Shortcut |
|---|---|
| Switch to workspace 1–9 | `Cmd + 1–9` |
| Switch to workspace 10 | `Cmd + 0` (if configured) |
| Move window to workspace 1–9 | `Shift + Cmd + 1–9` |
| Switch to previous workspace (back-and-forth) | `Ctrl + Opt + Tab` |
| Switch to next workspace | _unassigned_ |
| Switch to previous workspace (sequential) | _unassigned_ |
| Move window to workspace up/down | `Ctrl + Shift + Cmd + ↑ / ↓` |
| Move column to workspace up/down | `Ctrl + Shift + Cmd + PgUp / PgDn` (Niri) |

---

## Focus & Navigation

| Action | Shortcut |
|---|---|
| Focus left / down / up / right | `Cmd + H` / `J` / `K` / `L` |
| Focus previous window | `Cmd + Tab` (Niri) |
| Focus first / last column | `Cmd + Home` / `End` (Niri) |
| Focus column 1–9 | `Ctrl + Cmd + 1–9` (Niri) |
| Focus next monitor | `Ctrl + Cmd + Tab` |
| Focus previous monitor | _unassigned_ |
| Focus last monitor | `Ctrl + Cmd + \`` |
| Toggle command palette | `Ctrl + Opt + Space` |
| Open menu anywhere | `Ctrl + Opt + M` |

---

## Moving Windows

| Action | Shortcut |
|---|---|
| Move window left / down / up / right | `Shift + Cmd + H` / `J` / `K` / `L` |
| Move column left / right | `Ctrl + Shift + Cmd + ← / →` (Niri) |

---

## Layout & Sizing

### Niri & Dwindle (shared)

| Action | Shortcut |
|---|---|
| Toggle fullscreen | `Cmd + Return` |
| Balance sizes | `Shift + Cmd + B` |
| Cycle column width forward | `Cmd + .` |
| Cycle column width backward | `Cmd + ,` |
| Toggle workspace layout (Niri ↔ Dwindle) | `Shift + Cmd + C` |
| Raise all floating windows | `Shift + Cmd + R` |
| Toggle focused window floating | _unassigned_ |

### Niri only

| Action | Shortcut |
|---|---|
| Toggle column tabbed | `Opt + T` |
| Toggle column full-width | `Shift + Cmd + D` |
| Toggle overview (exposé) | `Shift + Cmd + O` |

### Dwindle only

| Action | Shortcut |
|---|---|
| Resize grow left / right / up / down | `Opt + H` / `L` / `K` / `J` |
| Resize shrink left / right / up / down | `Opt + Shift + L` / `H` / `J` / `K` |
| Move to root | _unassigned_ |
| Toggle split | _unassigned_ |
| Preselect left / right / up / down | _unassigned_ |

---

## Quake Terminal

| Action | Shortcut |
|---|---|
| Toggle Quake terminal | `Opt + \`` (backtick) |
| New tab | `Cmd + T` |
| Close tab | `Cmd + W` |
| Next / previous tab | `Cmd + Shift + ]` / `[` |
| Select tab 1–9 | `Cmd + 1–9` |
| Split pane (horizontal / vertical) | `Cmd + D` / `Cmd + Shift + D` |
| Close pane | `Cmd + Shift + W` |
| Navigate pane | `Cmd + Opt + ↑↓←→` |

---

## Special Features

| Action | Shortcut |
|---|---|
| Toggle overview (workspace exposé) | `Shift + Cmd + O` |
| Open command palette | `Ctrl + Opt + Space` |
| Open menu anywhere | `Ctrl + Opt + M` |
| Assign window to scratchpad | _unassigned_ |
| Toggle scratchpad window | _unassigned_ |
| Rescue offscreen windows | _unassigned_ |

---

## IPC & CLI

OmniWM ships with `omniwmctl` (at `/opt/homebrew/bin/omniwmctl` when installed via Homebrew).

```bash
# Enable IPC (required) — do this once from the OmniWM menu bar
# or set ipcEnabled = true in Nix config

# Focus
omniwmctl command focus left
omniwmctl command focus right

# Workspaces
omniwmctl command switch-workspace 3
omniwmctl command move-to-workspace 5

# Queries
omniwmctl query workspaces --format table
omniwmctl query windows --visible --format table
omniwmctl query focused-window --format json

# Live events
omniwmctl subscribe focus
omniwmctl watch active-workspace --exec ./on-workspace-change.sh

# Window rules
omniwmctl rule add --bundle-id com.apple.finder --layout float
omniwmctl rule apply
```

---

## Tips

- **Niri** (default): Windows stack in vertical columns that scroll horizontally. Best on wide monitors.
- **Dwindle**: Binary space partition — each new window splits the screen. Best for predictable layouts.
- Press `Shift + Cmd + C` to toggle between layouts per-workspace.
- Use the OmniWM menu bar icon → **Settings** to adjust keybindings, gaps, and appearance visually.
- The config file at `~/.config/omniwm/settings.toml` is live-reloaded — edit it with any text editor.
- Hold `Opt` and drag a tiled window to swap with another (Niri).
- Hold `Opt + Shift` and scroll to scroll through columns (Niri).
