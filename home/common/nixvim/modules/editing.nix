# modules/editing.nix
# Editing helpers: autopairs, comments, todo-highlights, sleuth.
{ ... }:
{
  # ── Mini.pairs: auto-close brackets, quotes ────────────
  plugins.mini = {
    enable = true;
    modules = {
      # Enable pairs with sensible defaults
      pairs = { };
    };
  };

  # ── Comment.nvim: easy commenting (gc/gcc) ────────────
  plugins.comment = {
    enable = true;
    settings = {
      mappings = {
        basic = true;
        extra = true;
      };
      toggler = {
        line = "gcc";
        block = "gbc";
      };
      opleader = {
        line = "gc";
        block = "gb";
      };
    };
  };

  # ── Todo-comments: highlight TODO/FIXME/HACK ───────────
  plugins.todo-comments = {
    enable = true;
    settings = {
      signs = true;
      merge_keywords = true;
      keywords = {
        TODO = {
          icon = " ";
          color = "warning";
          alt = [
            "WIP"
            "WORK"
          ];
        };
        FIX = {
          icon = " ";
          color = "error";
          alt = [
            "FIXME"
            "BUG"
            "FIXIT"
            "ISSUE"
          ];
        };
        HACK = {
          icon = " ";
          color = "info";
          alt = [
            "HACKY"
            "UGLY"
          ];
        };
        NOTE = {
          icon = " ";
          color = "hint";
          alt = [
            "INFO"
            "IDEA"
            "IMPORTANT"
          ];
        };
        WARN = {
          icon = " ";
          color = "warning";
          alt = [
            "WARNING"
            "XXX"
            "CAUTION"
          ];
        };
        PERF = {
          icon = " ";
          color = "warning";
          alt = [
            "OPTIMIZE"
            "PERFORMANCE"
            "SLOW"
          ];
        };
        TEST = {
          icon = "󰙨 ";
          color = "test";
          alt = [
            "TESTING"
            "PASS"
            "FAIL"
          ];
        };
      };
      highlight = {
        before = "bg";
        keyword = "wide";
        after = "fg";
        pattern = [
          ".*<(KEYWORDS)\s*:"
          ".*<(KEYWORDS)\s*("
        ];
        comments_only = true;
        max_line_len = 400;
        exclude = [
          "alpha"
          "TelescopePrompt"
        ];
      };
      search = {
        pattern = "\\b(KEYWORDS):";
      };
    };
  };

  # ── IlluminatedWords: highlight word under cursor ──────
  plugins.illuminate = {
    enable = true;
    settings = {
      delay = 200;
      filetypes_denylist = [
        "alpha"
        "NvimTree"
        "TelescopePrompt"
        "Trouble"
        "toggleterm"
        "neo-tree"
        "lazy"
        "mason"
      ];
      under_cursor = false;
      large_file_cutoff = 2000;
      large_file_overrides = {
        providers = [ "lsp" ];
      };
    };
  };
}
