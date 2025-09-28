# Zsh Configuration

This document provides an overview of the Zsh configuration managed by Nix Home Manager. The goal is to create a powerful, efficient, and user-friendly command-line experience. The entire configuration is declaratively managed in the `default.nix` file.

## Key Features

### Oh-My-Zsh

This configuration uses the popular [Oh-My-Zsh](https://ohmyz.sh/) framework to manage themes and plugins.

- **Theme**: `robbyrussell` is used for a clean and simple prompt.
- **Plugins**: A curated list of plugins is enabled to add useful features and completions for tools like:
  - `git`
  - `docker` & `docker-compose`
  - `fzf` (fuzzy finder)
  - `gh` (GitHub CLI)
  - `gcloud` (Google Cloud SDK)
  - `node`, `npm`, `nvm`
  - And many more for general productivity.

### Enhanced Shell Experience

- **Autosuggestions**: The shell suggests commands as you type based on your command history.
  - `zsh-autosuggestions` plugin is configured to use history and completion for suggestions.
  - Asynchronous mode is enabled for better performance.
- **Syntax Highlighting**: Provides real-time highlighting for commands and their arguments. This helps catch syntax errors before you even run the command. Dangerous commands like `rm -rf *` are highlighted in red as a warning.
  - `zsh-syntax-highlighting` plugin is used for syntax highlighting.
  - Various styles are defined for different command elements (comments, aliases, commands, options, etc.).
- **Auto CD**: You can navigate to a directory by simply typing its name without the `cd` command.
  - `AUTO_CD` option is enabled.
- **Spelling Correction**: Automatically corrects typos in commands.
  - `CORRECT` option is enabled.

### Powerful History

- **Large & Shared**: History is configured to save 50,000 entries and is shared across all open terminal sessions.
  - `HISTSIZE` and `SAVEHIST` are set to 50000.
  - `SHARE_HISTORY` option is enabled.
- **Smart Filtering**: The configuration is set to ignore duplicate commands and commands that start with a space, keeping your history clean and relevant.
  - `HIST_IGNORE_DUPS` and `HIST_IGNORE_SPACE` options are enabled.
- **History Substring Search**: You can type a part of a command and use the up/down arrow keys to search through your history for matching commands.
  - `history-substring-search` plugin is enabled.
  - Key bindings are set for up and down arrow keys in both emacs and vicmd modes.

### Navigation

- **CD Path**: You can quickly `cd` into subdirectories of `~` and `~/Projects` from any location.
  - `cdpath` is configured to include `~` and `~/Projects`.\
- **Directory Hashes**: Provides short aliases for frequently used directories:
  - `~docs`: `~/Documents`
  - `~dl`: `~/Downloads`
  - `~proj`: `~/Projects`
  - `~conf`: `~/.config`
  - `dirHashes` option is used to define these shortcuts.

### Aliases

A rich set of aliases is provided to speed up common workflows.

#### Shell Aliases (Command Replacements)

- **Modern Replacements**:
  - `ls`, `l`, `ll`, `la`, `tree` are replaced with `eza` for better output with git integration and icons.
  - `cat` is replaced with `bat` for syntax highlighting.
  - `find` is replaced with `fd` for faster and more intuitive file searching.
  - `ps` is replaced with `procs` for a modern process viewer.
- **Navigation**:
  - `..` -> `cd ..`
  - `...` -> `cd ../..`
- **Git**:
  - `g` -> `git`
  - `gs` -> `git status`
  - `ga` -> `git add`
  - `gc` -> `git commit`
- **Safety**:
  - `rm`, `cp`, `mv` are aliased to their interactive (`-i`) versions to prevent accidental overwrites.
- **Nix**:
  - `nrs` -> `sudo nixos-rebuild switch`
  - `hms` -> `home-manager switch`
  - `nfu` -> `nix flake update`

#### Global Aliases (Can be used anywhere)

- `G` -> `| grep`
- `L` -> `| less`
- `J` -> `| jq`
- `N` -> `> /dev/null 2>&1` (redirect stdout and stderr to null)

### Custom Functions

- `mkcd`: Creates a directory and immediately changes into it.
  - Usage: `mkcd my_new_directory`
  - Defined as a `siteFunction`.
- `extract`: A versatile function to extract any type of archive file (`.zip`, `.tar.gz`, `.rar`, etc.).
  - Usage: `extract archive.tar.gz`
  - Defined as a `siteFunction`.

## Configuration

This Zsh setup is managed declaratively through the `default.nix` file in this directory. To customize your shell, you can modify this file and apply the changes by running `home-manager switch`.