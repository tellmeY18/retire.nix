# modules/lang.nix
# Treesitter and language-specific configuration.
{ ... }:
{
  # ── Treesitter: superior syntax highlighting ───────────
  plugins.treesitter = {
    enable = true;
    settings = {
      ensure_installed = [
        "nix"
        "rust"
        "python"
        "javascript"
        "typescript"
        "tsx"
        "lua"
        "vim"
        "vimdoc"
        "bash"
        "c"
        "cmake"
        "comment"
        "css"
        "diff"
        "dockerfile"
        "gitcommit"
        "gitignore"
        "go"
        "gomod"
        "gosum"
        "gotmpl"
        "hcl"
        "html"
        "http"
        "java"
        "json"
        "jsonc"
        "latex"
        "llvm"
        "luadoc"
        "make"
        "markdown"
        "markdown_inline"
        "matlab"
        "mermaid"
        "perl"
        "printf"
        "proto"
        "python"
        "query"
        "regex"
        "ruby"
        "rust"
        "scss"
        "sql"
        "ssh_config"
        "strace"
        "toml"
        "typescript"
        "typst"
        "vim"
        "vimdoc"
        "yaml"
        "zig"
      ];
      highlight = {
        enable = true;
        use_languagetree = true;
        additional_vim_regex_highlighting = false;
      };
      indent = {
        enable = true;
      };
      incremental_selection = {
        enable = true;
        keymaps = {
          init_selection = "<CR>";
          node_incremental = "<CR>";
          scope_incremental = "<S-CR>";
          node_decremental = "<BS>";
        };
      };
      textobjects = {
        select = {
          enable = true;
          lookahead = true;
          keymaps = {
            "af" = "@function.outer";
            "if" = "@function.inner";
            "ac" = "@class.outer";
            "ic" = "@class.inner";
            "ap" = "@parameter.outer";
            "ip" = "@parameter.inner";
          };
        };
        move = {
          enable = true;
          set_jumps = true;
          goto_next_start = {
            "]]" = "@function.outer";
          };
          goto_previous_start = {
            "[[" = "@function.outer";
          };
        };
      };
      textsubjects = {
        enable = true;
        keymaps = {
          "." = "@textsubjects";
          ";" = "@textsubjects.outer";
        };
      };
    };
  };

  # ── Treesitter-context: show function/class context ───
  plugins.treesitter-context = {
    enable = true;
    settings = {
      enable = true;
      max_lines = 5;
      min_window_height = 10;
      line_numbers = true;
      multiline_threshold = 20;
      trim_scope = "outer";
      mode = "topline";
      separator = "─";
      zindex = 20;
    };
  };

  # ── Treesitter-textobjects (handled in treesitter settings) ─
  plugins.treesitter-textobjects = {
    enable = true;
  };
}
