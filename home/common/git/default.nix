{  pkgs, ... }:

{
  # Git configuration
  programs.git = {
    enable = true;
    package = pkgs.git;

    # User configuration
    userName = "Vysakh Premkumar";
    userEmail = "vysakhpr218@gmail.com";

    # Core settings
    extraConfig = {
      init = {
        defaultBranch = "main";
      };

      pull = {
        rebase = true;
      };

      core = {
        editor = "vim";
        autocrlf = false;
        safecrlf = false;
      };

      push = {
        default = "simple";
        autoSetupRemote = true;
      };

      branch = {
        autosetupmerge = "always";
        autosetuprebase = "always";
      };

      merge = {
        tool = "vimdiff";
        conflictstyle = "diff3";
      };

      diff = {
        tool = "vimdiff";
        colorMoved = "default";
      };

      rerere = {
        enabled = true;
      };

      color = {
        ui = true;
        branch = "auto";
        diff = "auto";
        status = "auto";
      };

      status = {
        showUntrackedFiles = "all";
      };

      log = {
        date = "relative";
      };

      format = {
        pretty = "format:%C(yellow)%h%Creset -%C(red)%d%Creset %s %C(dim green)(%an)%Creset";
      };
    };

    # Git aliases
    aliases = {
      # Basic shortcuts
      st = "status";
      co = "checkout";
      br = "branch";
      ci = "commit";
      df = "diff";
      lg = "log --oneline";

      # More complex aliases
      unstage = "reset HEAD --";
      last = "log -1 HEAD";
      visual = "!gitk";

      # Pretty log formats
      graph = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
      history = "log --pretty=format:'%h %ad | %s%d [%an]' --graph --date=short";

      # Useful shortcuts
      amend = "commit --amend";
      wipe = "add -A && commit -qm 'WIPE SAVEPOINT' && git reset HEAD~1 --hard";
      save = "!git add -A && git commit -m 'SAVEPOINT'";
      undo = "reset HEAD~1 --mixed";

      # Branch management
      branches = "branch -a";
      tags = "tag -l";
      remotes = "remote -v";

      # Find and cleanup
      find = "!git ls-files | grep -i";
      cleanup = "!git branch --merged | grep -v '\\*\\|master\\|main\\|develop' | xargs -n 1 git branch -d";
    };

    # Git ignore patterns
    ignores = [
      # macOS
      ".DS_Store"
      ".AppleDouble"
      ".LSOverride"
      "._*"

      # Linux
      "*~"
      ".fuse_hidden*"
      ".directory"
      ".Trash-*"

      # Windows
      "Thumbs.db"
      "ehthumbs.db"
      "Desktop.ini"

      # Editors
      ".vscode/"
      ".idea/"
      "*.swp"
      "*.swo"
      "*~"

      # Logs
      "*.log"
      "logs/"

      # Runtime data
      "pids/"
      "*.pid"
      "*.seed"

      # Coverage directory used by tools like istanbul
      "coverage/"

      # Dependency directories
      "node_modules/"
      ".npm"
      ".yarn/"

      # Optional npm cache directory
      ".npm"

      # Output of 'npm pack'
      "*.tgz"

      # Build outputs
      "dist/"
      "build/"
      "target/"
      "out/"

      # Environment files
      ".env"
      ".env.local"
      ".env.*.local"

      # Temporary files
      "tmp/"
      "temp/"
      ".tmp"
      ".temp"
    ];

    # Git LFS
    lfs = {
      enable = true;
    };

    # Delta for better diffs
    delta = {
      enable = true;
      options = {
        navigate = true;
        light = false;
        side-by-side = true;
        line-numbers = true;
        syntax-theme = "Dracula";
        plus-style = "syntax #012800";
        minus-style = "syntax #340001";
        map-styles = "bold purple => syntax #330f29, bold cyan => syntax #0e4344";
        file-style = "bold yellow ul";
        file-decoration-style = "none";
        hunk-header-decoration-style = "cyan box ul";
        line-numbers-minus-style = "#B10036";
        line-numbers-plus-style = "#03a4ff";
        line-numbers-left-format = "{nm:>4}┊";
        line-numbers-right-format = "{np:>4}│";
        line-numbers-left-style = "cyan";
        line-numbers-right-style = "cyan";
      };
    };
  };
}
