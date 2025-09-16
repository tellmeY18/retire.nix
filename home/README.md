# Home Manager Configurations

This directory contains Home Manager configurations for both Darwin (macOS) and NixOS systems.

## Structure

- `common.nix` - Shared configuration between all systems
- `darwin.nix` - macOS-specific Home Manager configuration  
- `chopper.nix` - NixOS-specific Home Manager configuration

## Usage

### Integrated with System Configurations

Home Manager is already integrated into both system configurations:

- **Darwin**: Automatically applies when rebuilding with `darwin-rebuild switch --flake .#Vysakhs-MacBook-Pro`
- **NixOS**: Automatically applies when rebuilding with `nixos-rebuild switch --flake .#chopper`

### Standalone Home Manager

You can also use Home Manager independently:

```bash
# For Darwin (macOS)
home-manager switch --flake .#mathewalex@Vysakhs-MacBook-Pro

# For NixOS
home-manager switch --flake .#mathew@chopper
```

## Configuration Details

### Common Configuration (`common.nix`)

Includes:
- **Development tools**: git, python3, rust, go, gcc, docker, docker-compose
- **CLI utilities**: eza, bat, ripgrep, fd, jq, htop, tree, tmux
- **Shell configuration**: zsh with autosuggestions, syntax highlighting, and completions
- **FZF integration**: fuzzy finder with file/directory/history search
- **Direnv support**: automatic environment loading with nix-direnv
- **Nix-index**: command-not-found functionality for Nix packages
- **Git configuration**: sensible defaults with rebase strategy
- **Tmux**: mouse support, sensible plugin, custom keybindings

### Darwin-specific (`darwin.nix`)

Adds:
- **macOS tools**: mas (App Store CLI), zoxide
- **Development**: docker, docker-compose
- **Homebrew integration**: PATH setup and environment variables
- **macOS aliases**: showfiles/hidefiles for Finder
- **Environment**: macOS-specific paths and variables

### NixOS-specific (`chopper.nix`) 

Adds:
- **GUI applications**: firefox, chromium
- **System monitoring**: iotop, lsof, strace, nethogs, ncdu
- **Network tools**: nmap, netcat, tcpdump, wireshark-cli
- **Development**: postgresql, redis, sqlite
- **Linux utilities**: xclip, flatpak support
- **System aliases**: systemctl, journalctl, docker shortcuts

## Features Migrated from System

The following configurations have been migrated from system-level to Home Manager:

- **ZSH**: Full shell configuration with FZF integration
- **Tmux**: Terminal multiplexer with sensible defaults and plugins
- **Direnv**: Automatic environment loading for development projects
- **Nix-index**: Command-not-found functionality

This provides better user-level control and doesn't require system rebuilds for changes.

## Customization

1. **Git**: Update email in `common.nix` git configuration
2. **Packages**: Modify package lists in each file as needed
3. **Dotfiles**: Add your own by configuring `home.file`
4. **Shell**: Customize aliases and environment variables
5. **FZF**: Adjust search commands and preview options
6. **Tmux**: Modify keybindings and plugins in the configuration

## Quick Start

1. Update the email in `common.nix` git configuration
2. Run `nh home switch .` to apply changes
3. Open a new terminal to get the full zsh configuration
4. Test tools: `eza`, `fzf`, `tmux`, etc.

## Available Features

- **Ctrl+R**: FZF history search in zsh
- **Ctrl+T**: FZF file finder
- **Alt+C**: FZF directory changer
- **`ll`, `la`**: Enhanced ls aliases with eza
- **Direnv**: Automatic `.envrc` loading in project directories
- **Command-not-found**: Suggests nix packages for missing commands

## Troubleshooting

- If Home Manager conflicts exist, use `--backup-extension .backup`
- Use `home-manager generations` to see previous configurations
- Roll back with `home-manager switch --switch-generation X`
- New shell features require opening a new terminal session