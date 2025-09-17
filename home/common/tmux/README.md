nix/home/common/tmux/README.md#L1-400
# tmux — Nix Home Module

This repository contains a Nix module for configuring `tmux` (the terminal multiplexer) for Home Manager / NixOS users. It is designed to be usable out-of-the-box, with sensible defaults and a set of curated plugins and keybindings that make tmux approachable even if you've never used it before.

This README is written so that someone with zero prior tmux knowledge can:
- understand what tmux is and why you might use it,
- enable this tmux configuration via Nix,
- perform common actions (start a session, split panes, copy text, navigate),
- understand the included plugins and defaults,
- customize the configuration for your needs.

---

Table of contents
- What is tmux?
- Prerequisites
- How to enable this module (Nix Home / NixOS)
- Quickstart — basic commands and workflows
- Keybindings you should know (this config)
- Plugins included and what they do
- Customization & tips
- Troubleshooting & FAQ
- Files and locations referenced by this module

---

What is tmux?
-------------
`tmux` is a terminal multiplexer. It lets you:
- run multiple terminal sessions inside a single terminal window,
- split a single terminal into multiple panes,
- detach from a session and reattach later (useful over SSH or when restarting your terminal),
- persist sessions and restore them later (with plugins).

This Nix module configures `tmux` with a friendly theme, useful plugins, and keybindings that prioritize productivity and discoverability.

---

Prerequisites
-------------
- Nix + Home Manager or NixOS (this module is intended to be included in your Nix configuration)
- A terminal that supports 256 colours (the module sets `terminal = "screen-256color"`)
- zsh should be available in your system (this module sets tmux to use `${pkgs.zsh}/bin/zsh` as the default shell)
- On macOS: `pbcopy` is used to copy selections to the system clipboard. On Linux, install your preferred clipboard utility (`xclip`, `xsel`, or `wl-copy`) and adjust bindings if needed.

---

How to enable this module
--------------------------
If your dotfiles repo is located with this module at `nix/home/common/tmux/default.nix`, you can import the module in your Home Manager or NixOS configuration.

Example (Home Manager `home.nix`):
```/dev/null/home.nix#L1-40
{ config, pkgs, ... }:
{
  imports = [
    # Path to this tmux module in your repo
    ./nix/home/common/tmux/default.nix
  ];

  # ...the rest of your Home Manager config...
}
```

After adding the import, apply your configuration:
- Home Manager: `home-manager switch`
- NixOS: `sudo nixos-rebuild switch` (if you included it in your system config)
- If you use flakes: include/override accordingly and run your flake activation command.

Notes:
- This module sets `programs.tmux.enable = true;` and configures plugins via `pkgs.tmuxPlugins`.
- The module configures tmux to use zsh as the default shell (`shell = "${pkgs.zsh}/bin/zsh"` and explicit `default-shell`/`default-command` settings).
- The module stores tmux logs and plugin configurations in places described in the Files section below.

---

Quickstart — basic commands and workflows
-----------------------------------------

Starting and attaching
- Start a new tmux session: `tmux new-session -s mysession`
- List sessions: `tmux ls`
- Attach to a session: `tmux attach -t mysession`
- Detach from a session: press the tmux prefix, then `d` (prefix + d)

Prefix key
- This configuration sets the tmux prefix to Ctrl‑a (displayed as `C-a`).
  - "prefix" means: press Ctrl-a, then press the next key to perform a tmux command.
  - Example: "prefix, c" creates a new window (so press Ctrl-a, then `c`).

Basic navigation and pane/window management
- Create a new window in the current path: prefix + `c`
- Split panes:
  - prefix + `|` = split pane horizontally (creates left/right)
  - prefix + `-` = split pane vertically (creates top/bottom)
- Navigate panes without using the prefix:
  - Alt + Arrow (M-Left / M-Right / M-Up / M-Down)
- Switch windows quickly:
  - Shift + Left/Right (S-Left / S-Right) to go to previous/next window
- Resize panes: this config enables pane resize shortcuts (you can also use the mouse)

Copy & paste (vi-style)
- Enter copy mode (typically: prefix + `[` — tmux default).
- In copy-mode-vi:
  - Press `v` to begin visual selection,
  - Move to select text, then press `y` to yank/copy.
- On macOS this configuration pipes copied text to `pbcopy` (so it ends up in the macOS clipboard).
- The `yank` plugin is configured to support mouse selections as clipboard as well.

Persisting sessions (auto-save/restore)
- This config includes `resurrect` and `continuum` plugins:
  - `continuum` is configured to save sessions every 15 minutes and restore on boot (see module `extraConfig`).
  - This means if you log out or restart, tmux sessions can be restored automatically.
- Resurrect also captures pane contents and shell history (within limitations).

Reload configuration
- To reload the tmux configuration file, press prefix + `r`.
  - That runs: `source-file ~/.config/tmux/tmux.conf` and shows message "Config reloaded!"

---

Keybindings summary (what this module changes)
----------------------------------------------
- Prefix: `Ctrl-a` (`C-a`)
- Reload config: prefix + `r`
- New window: prefix + `c` (in current path)
- Split horizontally: prefix + `|`
- Split vertically: prefix + `-`
- Unbound default split keys: the default `"` and `%` are unbound to prefer the new keys above
- Pane navigation without prefix: Alt + arrow keys (M-Left, M-Right, M-Up, M-Down)
- Window switching without prefix: Shift + Left/Right (S-Left / S-Right)
- Copy-mode-vi bindings:
  - `v` to begin selection
  - `y` to copy (pipes to `pbcopy` on macOS)
  - `r` to toggle rectangle selection mode
- Synchronize panes toggle: prefix + `a` (toggle `synchronize-panes` and display a message)

---

Plugins included and why they are useful
----------------------------------------
This module configures `tmux` with a set of plugins (from `pkgs.tmuxPlugins`). Highlights:

- sensible
  - Basic sane defaults for tmux.
- pain-control
  - Small UX improvements to reduce friction.
- prefix-highlight
  - Shows a visual indicator when the prefix has been pressed.
- resurrect
  - Saves tmux sessions (layout, windows, commands). Combined with `continuum` for automatic saving/restoring.
- continuum
  - Auto-save and auto-restore of tmux sessions. Configured here to save every 15 minutes and restore on boot.
- yank
  - Improves copy/paste integration with system clipboard. Configured to use `pbcopy` and to handle mouse selections into the clipboard.
- cpu and battery
  - Status-line widgets that show CPU usage and battery percentage with icons/colors.
- sidebar
  - A sidebar tree view (file tree) can be invoked by plugin key — configured to use `tree -C`.
- logging
  - Writes tmux logs to `~/.tmux/logs` (configurable).
- open
  - Add helper to open URLs using a configured search pattern.

Plugin configuration is applied inside `extraConfig` and via `plugins` declarations in the module. If you need to customize plugin behaviour, edit the `extraConfig` section or override the plugin config in your own Nix code.

---

Appearance & status bar
-----------------------
- Status bar is styled (colors and layout) with left and right segments showing host/session, CPU, battery, and date/time.
- Window list and active window have customized coloring and formatting.
- The status bar interval is 2 seconds by default.

---

Customization & where to change things
--------------------------------------
You can customize most behaviour in two ways:

1. Override values in your Home Manager / NixOS config when importing this module:
```/dev/null/home-override-example.nix#L1-40
{
  # Example: override prefix and disable mouse
  programs.tmux = {
    prefix = "C-b";      # change prefix to Ctrl-b
    mouse = false;       # disable mouse support
  };
}
```

2. Edit the `extraConfig` in `nix/home/common/tmux/default.nix` to change raw tmux options and keybindings. The `extraConfig` block contains:
- theme and status line configuration,
- key bindings,
- appearance options (pane borders, message style),
- plugin-specific `set -g @...` settings.

If you modify plugin behaviour (for example, `yank` to use `wl-copy`), update the appropriate `@` variables in the `extraConfig`.

---

Troubleshooting & notes
-----------------------
- Shell not working (tmux not using zsh):
  - This module sets both `shell = "${pkgs.zsh}/bin/zsh"` and explicit `default-shell`/`default-command` in tmux config.
  - If tmux still uses a different shell, verify zsh is installed: `which zsh` should return a path.
  - After applying the configuration, kill any existing tmux sessions and start fresh: `tmux kill-server && tmux`.
- Clipboard not working on Linux:
  - The configuration uses `pbcopy` for copying on macOS. On Linux, install `xclip`, `xsel`, or `wl-clipboard` and change the copy command in the `copy-mode-vi y` binding or change `@yank_action` to call your clipboard utility.
- Plugins not installed/working:
  - With Nix-managed tmux plugins, ensure you rebuild your Home Manager/NixOS configuration after changing plugin lists:
    - `home-manager switch` or `sudo nixos-rebuild switch`.
- Sessions not restoring:
  - `continuum` is configured to save every 15 minutes and to restore on boot. If you want immediate manual control, consult tmux-resurrect/continuum docs for manual save/restore steps (plugin keybindings can vary).
- Logs:
  - The `logging` plugin is configured to write logs to `$HOME/.tmux/logs`. Inspect files there if you have plugin or tmux problems.

---

Files and locations referenced by this module
--------------------------------------------
- Module file (this repo): `nix/home/common/tmux/default.nix`
  - This is the Nix module you import into Home Manager / NixOS.
- User tmux config path used by the reload binding: `~/.config/tmux/tmux.conf`
  - Reload via prefix + `r` runs: `source-file ~/.config/tmux/tmux.conf`
- Logs directory (configured by plugin): `~/.tmux/logs`

If you'd like to inspect the module file used to build this configuration, see:
```nix/home/common/tmux/default.nix#L1-400
# (The module code source lives here in the repo: nix/home/common/tmux/default.nix)
```

---

FAQ
---
Q: I don't know what "prefix" means.
A: The tmux "prefix" is a leader key that you press first to tell tmux the next key is a command. In this config the prefix is Ctrl‑a (C-a). So to create a new window you press Ctrl‑a, then release, then press `c`.

Q: How do I split a pane?
A: Press the prefix (Ctrl-a) then `|` for a left/right split, or prefix then `-` for top/bottom.

Q: How do I copy and paste text?
A: Enter copy mode (prefix + `[`), then press `v` to start a selection (vi-like), move the cursor to select, then press `y` to copy to the system clipboard (on macOS this uses `pbcopy`).

Q: Can I change the prefix?
A: Yes — override `programs.tmux.prefix` in your Nix config (example shown above).

---

Final notes
-----------
This tmux setup aims to balance ergonomics with sensible defaults and a curated set of plugins. If anything is unclear or you want a behavior changed (different prefix, different clipboard tool, additional plugins), edit your Nix config to override options and rebuild with Home Manager or NixOS.

If you want help changing a specific option or adding a plugin, tell me what you want to change and whether you're using Home Manager or NixOS, and I can provide the exact snippet to add to your configuration.

Enjoy tmux!