# Home Manager Configurations

Per-user environment managed by [Home Manager](https://nix-community.github.io/home-manager/).
Both macOS and NixOS share a common module set; platform-specific modules
layer on top.

## Directory Layout

```
home/
├── darwin-home.nix        # HM entry point for macOS (imports common/ + darwin/)
├── linux-home.nix         # HM entry point for NixOS  (imports common/ + chopper/)
│
├── common/                # Cross-platform modules (imported by both hosts)
│   ├── default.nix        #   aggregates everything below
│   ├── direnv/            #   automatic .envrc loading (nix-direnv)
│   ├── firefox/           #   Firefox configuration
│   ├── fzf/               #   fuzzy finder integration
│   ├── git/               #   git config, aliases, delta
│   ├── jujutsu/           #   jj VCS config (currently commented out)
│   ├── kitty/             #   kitty terminal (cross-platform; uses lib.optionalAttrs
│   │                      #     for macOS / Linux-specific settings)
│   ├── packages/          #   shared CLI packages
│   ├── programs/          #   miscellaneous program settings
│   ├── tmux/              #   tmux config & plugins
│   ├── zed-editor/        #   Zed editor settings
│   └── zsh/               #   zsh + oh-my-zsh + autosuggestions + syntax highlighting
│                          #     (base theme "jonathan"; macOS overrides in darwin/zsh)
│
├── darwin/                # macOS-only modules
│   ├── default.nix
│   ├── emacs/             #   Emacs configuration
│   ├── packages/          #   mac-specific packages
│   ├── pulse/             #   PulseAudio / sound config
│   └── zsh/               #   macOS zsh overrides (Homebrew PATH, theme → robbyrussell)
│
└── chopper/               # chopper (NixOS) only modules
    ├── default.nix
    ├── packages/          #   linux-specific packages
    └── sway/              #   Sway window manager
```

## Entry Points

| File | Consumed by | Imports |
|---|---|---|
| `darwin-home.nix` | `homeConfigurations."mathewalex@Vysakhs-MacBook-Pro"` | `common/` + `darwin/` |
| `linux-home.nix` | `homeConfigurations."vysakh@chopper"` | `common/` + `chopper/` |

Home Manager is also pulled in as a module during system rebuilds
(`nh darwin switch` / `nh os switch`), so a standalone `home-manager switch`
is only needed when you want to update your user environment without
rebuilding the full system.

## Platform-specific configuration

Modules in `common/` use `lib.optionalAttrs pkgs.stdenv.isDarwin` and
`lib.optionalAttrs pkgs.stdenv.isLinux` guards to keep platform-specific
settings co-located with the rest of the module's config. This avoids
duplicating entire modules across `chopper/` and `darwin/`.

Modules that are **entirely** platform-specific (e.g. Sway, Emacs, Homebrew
setup) remain in the host-specific directories.

### kitty

All kitty configuration lives in `common/kitty/`. macOS-specific settings
(`macos_hide_titlebar`) and Linux-specific settings (Wayland/X11, clipboard
control) are gated with `lib.optionalAttrs`.

### zsh

The base zsh config (history, aliases, plugins, oh-my-zsh theme "jonathan")
lives in `common/zsh/`. The `darwin/zsh/` module overrides the theme to
"robbyrussell" via `lib.mkForce` and adds Homebrew PATH + macOS-specific
aliases.

## Usage

### Via system rebuild (recommended)

```sh
# macOS
nh darwin switch .

# NixOS
nh os switch .
```

### Standalone

```sh
# macOS
home-manager switch --flake .#mathewalex@Vysakhs-MacBook-Pro

# NixOS
home-manager switch --flake .#vysakh@chopper
```

## Adding a Module

1. Create a directory under `common/` (cross-platform) or `<host>/`
   (host-specific):

   ```
   home/common/my-tool/default.nix
   ```

2. Write the module — typically `{ pkgs, ... }: { ... }`.
3. Import it from the parent `default.nix`:

   ```nix
   # home/common/default.nix
   imports = [
     ./my-tool
     # …existing imports…
   ];
   ```

4. Rebuild: `nh darwin switch .` or `nh os switch .`.

### Platform guards

If a module has platform-specific bits, prefer co-locating them with guards
rather than creating a separate host-specific copy:

```nix
{ lib, pkgs, ... }:
{
  programs.my-tool = {
    settings = {
      # shared settings …
    }
    // (lib.optionalAttrs pkgs.stdenv.isDarwin {
      # macOS-only settings
    })
    // (lib.optionalAttrs pkgs.stdenv.isLinux {
      # Linux-only settings
    });
  };
}
```

Only create a separate module in `darwin/` or `chopper/` when the **entire**
module is platform-specific (e.g. Sway on Linux, Homebrew on macOS).

## Troubleshooting

- **Conflicting files** — pass `--backup-extension .backup` to
  `home-manager switch` if it complains about existing dotfiles.
- **List generations** — `home-manager generations`.
- **Roll back** — `home-manager switch --switch-generation <N>`.
- **New shell features** — open a fresh terminal after switching.
