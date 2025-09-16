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
- Essential development tools (git, nodejs, python3, rust, go)
- Shell configurations (bash, zsh with completions and syntax highlighting)
- Terminal multiplexer (tmux with sensible defaults)
- Common aliases and environment variables

### Darwin-specific (`darwin.nix`)

Adds:
- macOS App Store CLI (`mas`)
- Homebrew integration
- Docker tools
- macOS-specific environment variables

### NixOS-specific (`chopper.nix`) 

Adds:
- GUI applications (firefox, chromium)
- Linux system monitoring tools
- Network utilities
- Additional development tools

## Customization

1. Update email addresses in git configuration
2. Modify package lists in each file as needed
3. Add your own dotfiles by uncommenting and configuring `home.file`
4. Customize shell aliases and environment variables

## Quick Start

1. Update the email in `common.nix` git configuration
2. Rebuild your system configuration to apply changes
3. All tools and configurations will be automatically available

## Troubleshooting

- If Home Manager conflicts with existing configurations, backup and remove conflicting dotfiles
- Use `home-manager generations` to see previous configurations
- Roll back with `home-manager switch --switch-generation X` where X is the generation number