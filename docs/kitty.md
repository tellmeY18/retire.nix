# Kitty — Keybindings & Layout

> Generated from `home/common/kitty/default.nix`, which is the source of
> truth. If you change bindings there, update this file in the same commit.

---

## Where things live

| What | Path |
|------|------|
| Config source | `home/common/kitty/default.nix` |
| Session definitions | `home/common/kitty/sessions.nix` |
| Rendered config | `~/.config/kitty/kitty.conf` (symlinked by home-manager) |
| Session files | `~/.config/kitty/sessions/*.kitty-session` |
| Quick-access dropdown | `~/.config/kitty/quick-access-terminal.conf` |
| macOS launcher hotkey | `home/darwin/skhd/default.nix` |

Apply changes with `nh home switch ~/.config/nix`.

---

## The `kitty_mod` modifier

Every binding below is written as `kitty_mod+<key>`. `kitty_mod` is kitty's
own modifier alias, set per platform from a single `kittyMod` value in
`home/common/kitty/default.nix`:

| Platform | `kitty_mod` |
|---|---|
| macOS | `cmd` |
| Linux | `ctrl` |
| Other | `ctrl+shift` (kitty's default) |

So `kitty_mod+t` means **⌘T** on macOS and **Ctrl+T** on Linux. To change the
modifier everywhere, edit `kittyMod` — nothing else needs touching.

> **Linux warning.** `ctrl` collides with terminal control codes: `ctrl+c`
> becomes copy instead of SIGINT, `ctrl+z` stops suspending, `ctrl+r` stops
> reverse-searching, and so on. kitty defaults to `ctrl+shift` for exactly
> this reason. Currently harmless — no Linux host in this repo builds the
> home-manager kitty config — but fix `kittyMod` before adding one.

---

## Tabs

| Binding | Action | Notes |
|---|---|---|
| `kitty_mod+t` | New tab | Inherits current working directory |
| `kitty_mod+w` | Close tab | |
| `kitty_mod+→` | Next tab | |
| `kitty_mod+←` | Previous tab | |
| `kitty_mod+q` | Quit kitty | Closes all windows |

The tab bar sits on the **left edge**, powerline style, and shows the active
session name as a prefix when a session is loaded.

## Windows (splits)

| Binding | Action | Notes |
|---|---|---|
| `kitty_mod+enter` | New split | Inherits current working directory |
| `kitty_mod+n` | New OS window | Inherits current working directory |

## Layouts

Enabled layouts, in cycle order: `splits` → `tall` → `stack` → `grid`.
Splits auto-equalize when a window closes.

| Binding | Action |
|---|---|
| `kitty_mod+l` | Cycle to next layout |
| `kitty_mod+alt+z` | Toggle `stack` (zoom current window fullscreen) |
| `kitty_mod+r` | Enter resize mode (arrows resize, `esc` exits) |
| `kitty_mod+alt+e` | Equalize all window sizes |

## Sessions

| Binding | Action |
|---|---|
| `kitty_mod+s` | Session picker for `~/.config/kitty/sessions` |
| `kitty_mod+alt+s` | Save current layout as a new session |
| `kitty_mod+alt+←` | Jump to previous session |

Three sessions ship with the config:

| Session | Directory | Layout | Windows | Focused |
|---|---|---|---|---|
| `development` | `~/Projects` | `splits` | `nvim` + shell | Editor |
| `nix` | `~/.config/nix` | `splits` | `nvim` + build shell | Editor |
| `cluster-admin` | `~/.config/nix` | `tall` | `k9s` + shell | K9s |

Both `cluster-admin` windows get `KUBECONFIG=~/.kube/glug-infra.yaml` injected
via `launch --env`, so cluster commands work without exporting it by hand.

Saved sessions use `--relocatable`, so paths stay relative to the base dir and
survive being moved between machines.

### Adding a session

Sessions are data, not text — add an entry to `sessions` in
`home/common/kitty/sessions.nix`:

```nix
monitoring = {
  tab = "Monitoring";
  cwd = "${home}/.config/nix";
  layout = "tall";
  windows = [
    {
      title = "Logs";
      command = "k9s";
      env = kubeEnv;
      focus = true;
    }
    { title = "Shell"; }
  ];
};
```

Omit `command` for a plain shell. `focus = true` marks the window active on
open — note that kitty's `focus` directive takes no argument and applies to
the preceding `launch`, so a trailing `focus 0` focuses the *last* window, not
the first.

## Font size

| Binding | Action |
|---|---|
| `kitty_mod++` | Increase by 2.0 |
| `kitty_mod+-` | Decrease by 2.0 |
| `kitty_mod+backspace` | Reset to 12.0 |

## Clipboard

| Binding | Action |
|---|---|
| `kitty_mod+c` | Copy to clipboard |
| `kitty_mod+v` | Paste from clipboard |

`copy_on_select` is enabled, so selecting text already copies it. Trailing
whitespace is stripped intelligently (`strip_trailing_spaces smart`).

## Scrolling

| Binding | Action |
|---|---|
| `kitty_mod+↑` / `kitty_mod+↓` | Scroll one line |
| `kitty_mod+page_up` / `kitty_mod+page_down` | Scroll one page |
| `kitty_mod+home` / `kitty_mod+end` | Scroll to top / bottom |

Scrollback is 10 000 lines, with 100 MB of pager history.

## Shell integration

These depend on kitty's shell integration (enabled) and only work for commands
run at a real prompt.

| Binding | Action |
|---|---|
| `kitty_mod+g` | Show output of last command in the pager |
| `kitty_mod+alt+c` | Copy output of last command to clipboard |
| `kitty_mod+z` | Jump to previous prompt |
| `kitty_mod+x` | Jump to next prompt |
| `kitty_mod+/` | Search scrollback in the pager |

Commands taking longer than 10 s in a non-visible window raise a desktop
notification (`notify_on_cmd_finish invisible 10`).

## Discovery

| Binding | Action |
|---|---|
| `kitty_mod+f3` | Command palette — searchable list of every kitty action |
| `kitty_mod+e` | Hint every URL on screen, type a label to open it |

Use the command palette to find anything not bound here.

## Background opacity

A two-key leader sequence: press `kitty_mod+a`, release, then the second key.

| Binding | Action |
|---|---|
| `kitty_mod+a` then `-` | Decrease opacity by 0.05 |
| `kitty_mod+a` then `+` | Increase opacity by 0.05 |
| `kitty_mod+a` then `0` | Reset to default (0.85) |

Requires `dynamic_background_opacity`, which is enabled.

---

## Platform-specific

### macOS

| Binding | Action | Where |
|---|---|---|
| `alt+return` | Toggle quick-access dropdown terminal | skhd |
| `alt+b` | Open Firefox | skhd |
| `ctrl+cmd+drag` | Move the kitty window | macOS |

The dropdown is a 25-line overlay pinned to the top edge that hides on focus
loss — a separate `kitten quick-access-terminal` instance, not a normal window.

Windows are **fully undecorated** (`hide_window_decorations yes`): no titlebar,
no traffic lights, no rounded corners. They stay resizable, but there is no
titlebar to grab, hence `ctrl+cmd+drag` to move them.

### Linux

These are deliberately literal rather than `kitty_mod`-based, because they
follow X11/Wayland clipboard convention:

| Binding | Action |
|---|---|
| `ctrl+shift+insert` | Paste from clipboard |
| `shift+insert` | Paste from primary selection |

---

## Not bound here

kitty ships a large set of defaults that remain active alongside the above —
on macOS that includes the native `cmd+c` / `cmd+v` / `cmd+q` behaviours.

| Binding | Action |
|---|---|
| `kitty_mod+f3` | Command palette — search every available action |
| `kitty_mod+f6` (or `opt+cmd+,` on macOS) | Dump the fully-resolved config and every active binding |
| `kitty_mod+f1` | Open kitty's documentation |

When a binding here looks wrong, `kitty_mod+f6` shows what kitty actually
loaded, which is the fastest way to spot a conflict with a default.
