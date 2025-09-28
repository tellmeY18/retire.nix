{ config, pkgs, ... }:

{
  programs.zsh = {
    enable = true;
    package = pkgs.zsh;

    # Enable completion system
    enableCompletion = true;
    completionInit = "autoload -U compinit && compinit -d ${config.xdg.cacheHome}/zsh/zcompdump-$ZSH_VERSION";

    # Auto cd when typing directory name
    autocd = true;

    # Search path for cd command
    cdpath = [
      "."
      ".."
      "${config.home.homeDirectory}"
      "${config.home.homeDirectory}/Projects"
    ];

    # Directory hashes for quick navigation
    dirHashes = {
      docs = "${config.home.homeDirectory}/Documents";
      dl = "${config.home.homeDirectory}/Downloads";
      proj = "${config.home.homeDirectory}/Projects";
      conf = "${config.home.homeDirectory}/.config";
    };

    # Configure dot directory
    dotDir = "${config.xdg.configHome}/zsh";

    # Default keymap
    defaultKeymap = "emacs";

    # ZSH options
    setOptions = [
      "EXTENDED_HISTORY" # Write timestamps to history
      "HIST_EXPIRE_DUPS_FIRST" # Expire duplicates first
      "HIST_FIND_NO_DUPS" # Don't display duplicates during searches
      "HIST_IGNORE_DUPS" # Don't record duplicate commands
      "HIST_IGNORE_SPACE" # Don't record commands starting with space
      "HIST_REDUCE_BLANKS" # Remove superfluous blanks
      "HIST_SAVE_NO_DUPS" # Don't save duplicates
      "HIST_VERIFY" # Show command with history expansion
      "INC_APPEND_HISTORY" # Append to history immediately
      "SHARE_HISTORY" # Share history between sessions
      "AUTO_CD" # Auto cd to directory
      "AUTO_PUSHD" # Automatically push directories onto stack
      "PUSHD_IGNORE_DUPS" # Don't push duplicates onto stack
      "PUSHD_SILENT" # Don't print directory stack
      "CORRECT" # Spelling correction for commands
      "EXTENDED_GLOB" # Extended globbing
      "GLOB_DOTS" # Match dotfiles without explicit dot
      "NO_BEEP" # No beeping
      "INTERACTIVE_COMMENTS" # Allow comments in interactive shells
    ];

    # Enhanced history configuration
    history = {
      size = 50000;
      save = 50000;
      share = true;
      ignoreDups = true;
      ignoreSpace = true;
      expireDuplicatesFirst = true;
      extended = true;
      path = "${config.xdg.dataHome}/zsh/history";
    };

    # Enhanced autosuggestions
    autosuggestion = {
      enable = true;
      strategy = [ "history" "completion" ];
      highlight = "fg=#586e75";
    };

    # Enhanced syntax highlighting
    syntaxHighlighting = {
      enable = true;
      highlighters = [ "main" "brackets" "pattern" "cursor" "regexp" "root" "line" ];
      styles = {
        comment = "fg=black,bold";
        alias = "fg=magenta,bold";
        suffix-alias = "fg=magenta,bold";
        global-alias = "fg=magenta";
        function = "fg=magenta,bold";
        command = "fg=green";
        precommand = "fg=green,underline";
        autodirectory = "fg=yellow,underline";
        single-hyphen-option = "fg=cyan";
        double-hyphen-option = "fg=cyan";
        back-quoted-argument = "fg=blue";
        single-quoted-argument = "fg=yellow";
        double-quoted-argument = "fg=yellow";
        dollar-quoted-argument = "fg=yellow";
        rc-quote = "fg=magenta";
        dollar-double-quoted-argument = "fg=magenta";
        back-double-quoted-argument = "fg=magenta";
        back-dollar-quoted-argument = "fg=magenta";
        assign = "none";
        redirection = "fg=blue,bold";
        arg0 = "fg=green";
        default = "none";
        cursor = "standout";
      };
      patterns = {
        "rm -rf *" = "fg=white,bold,bg=red";
        "sudo rm -rf" = "fg=white,bold,bg=red";
      };
    };

    # Shell aliases
    shellAliases = {
      # Enhanced ls commands
      ll = "eza -la --git --icons";
      la = "eza -a --git --icons";
      l = "eza -l --git --icons";
      ls = "eza --icons";
      tree = "eza --tree --icons";

      # Navigation
      ".." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";
      "....." = "cd ../../../..";

      # Git shortcuts
      g = "git";
      ga = "git add";
      gc = "git commit";
      gco = "git checkout";
      gd = "git diff";
      gl = "git log --oneline";
      gp = "git push";
      gs = "git status";

      # System utilities
      grep = "grep --color=auto";
      fgrep = "fgrep --color=auto";
      egrep = "egrep --color=auto";
      cat = "bat";
      less = "bat";
      find = "fd";
      ps = "procs";
      top = "htop";

      # Nix utilities
      nrs = "sudo nixos-rebuild switch";
      nrt = "sudo nixos-rebuild test";
      hms = "home-manager switch";
      nfu = "nix flake update";
      nfc = "nix flake check";

      # Safety nets
      rm = "rm -i";
      cp = "cp -i";
      mv = "mv -i";

      # Quick edits
      zshrc = "$EDITOR ~/.config/zsh/.zshrc";
      nixconf = "$EDITOR ~/.config/nix/";
    };

    # Global aliases (can be used anywhere on command line)
    shellGlobalAliases = {
      "..." = "../..";
      "...." = "../../..";
      "....." = "../../../..";
      G = "| grep";
      L = "| less";
      H = "| head";
      T = "| tail";
      S = "| sort";
      U = "| uniq";
      J = "| jq";
      C = "| wc -l";
      N = "> /dev/null 2>&1";
      LL = "2>&1 | less";
      CA = "2>&1 | cat -A";
      NE = "2> /dev/null";
      NUL = "> /dev/null 2>&1";
    };

    # Session variables
    sessionVariables = {
      LESS = "-R";
      LESSHISTFILE = "${config.xdg.dataHome}/less/history";
      PAGER = "less";
      MANPAGER = "less -X";
    };

    # Local variables
    localVariables = {
      ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE = 20;
      ZSH_AUTOSUGGEST_USE_ASYNC = 1;
      ZSH_HIGHLIGHT_MAXLENGTH = 300;
    };

    # Oh-My-Zsh configuration
    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
        "docker"
        "docker-compose"
        "sudo"
        "command-not-found"
        "colored-man-pages"
        "extract"
        "z"
        "history-substring-search"
        "alias-finder"
        "aliases"
        "common-aliases"
        "copybuffer"
        "copypath"
        "dirhistory"
        "direnv"
        "emoji"
        "fzf"
        "gh"
        "globalias"
        "gcloud"
        "golang"
        "node"
        "npm"
        "nvm"
      ];
      extraConfig = ''
        # Oh-My-Zsh theme customization
        AGNOSTER_PROMPT_SEGMENTS[1]="prompt_status"
        AGNOSTER_PROMPT_SEGMENTS[2]="prompt_virtualenv"
        AGNOSTER_PROMPT_SEGMENTS[3]="prompt_context"
        AGNOSTER_PROMPT_SEGMENTS[4]="prompt_dir"
        AGNOSTER_PROMPT_SEGMENTS[5]="prompt_git"
        AGNOSTER_PROMPT_SEGMENTS[6]="prompt_end"

        # Disable oh-my-zsh auto-update
        DISABLE_AUTO_UPDATE="true"
        DISABLE_UPDATE_PROMPT="true"

        # History substring search key bindings
        bindkey '^[[A' history-substring-search-up
        bindkey '^[[B' history-substring-search-down
        bindkey -M vicmd 'k' history-substring-search-up
        bindkey -M vicmd 'j' history-substring-search-down
      '';
    };

    # Custom functions
    siteFunctions = {
      mkcd = ''
        mkdir -p "$1" && cd "$1"
      '';

      extract = ''
        if [ -f "$1" ] ; then
          case "$1" in
            *.tar.bz2)   , tar xjf "$1"     ;;
            *.tar.gz)    , tar xzf "$1"     ;;
            *.bz2)       , bunzip2 "$1"     ;;
            *.rar)       , unrar x "$1"     ;;
            *.gz)        , gunzip "$1"      ;;
            *.tar)       , tar xf "$1"      ;;
            *.tbz2)      , tar xjf "$1"     ;;
            *.tgz)       , tar xzf "$1"     ;;
            *.zip)       , unzip "$1"       ;;
            *.Z)         , uncompress "$1"  ;;
            *.7z)        , 7z x "$1"        ;;
            *.deb)       , ar x "$1"        ;;
            *.xz)        , xz -d "$1"       ;;
            *.lzma)      , lzma -d "$1"     ;;
            *.zst)       , zstd -d "$1"     ;;
            *)           echo "'$1' cannot be extracted via extract function" ;;
          esac
        else
          echo "'$1' is not a valid file"
        fi
      '';
    };
  };
}
