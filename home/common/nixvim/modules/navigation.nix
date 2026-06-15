# modules/navigation.nix
# File navigation: telescope, harpoon, flash, nvim-tree.
{ ... }:
{
  # ── Telescope: fuzzy finder ────────────────────────────
  plugins.telescope = {
    enable = true;
    extensions = {
      fzf-native = {
        enable = true;
      };
    };
    settings = {
      defaults = {
        prompt_prefix = " ";
        selection_caret = " ";
        path_display = [ "truncate" ];
        sorting_strategy = "ascending";
        layout_config = {
          horizontal = {
            prompt_position = "top";
            preview_width = 0.5;
            width = 0.8;
            height = 0.8;
          };
        };
        mappings = {
          i = {
            "<C-j>" = {
              action = "move_selection_next";
            };
            "<C-k>" = {
              action = "move_selection_previous";
            };
            "<C-n>" = {
              action = "cycle_history_next";
            };
            "<C-p>" = {
              action = "cycle_history_prev";
            };
          };
        };
        file_ignore_patterns = [
          "^.git/"
          "^.direnv/"
          "^result"
          "^target/"
          "^node_modules/"
          "%.lock"
        ];
        set_env = {
          COLORTERM = "truecolor";
        };
      };
      pickers = {
        find_files = {
          hidden = true;
          follow = true;
        };
        live_grep = {
          additional_args = [
            "--hidden"
            "--no-ignore"
          ];
        };
        buffers = {
          sort_mru = true;
          ignore_current_buffer = true;
        };
      };
    };
  };

  # ── Telescope extension: fzf-native (enabled above) ────

  # ── Harpoon: quick file marks ─────────────────────────
  plugins.harpoon = {
    enable = true;
    settings = {
      menu = {
        width.__raw = "vim.api.nvim_win_get_width(0) - 4";
      };
      global_settings = {
        save_on_toggle = false;
        sync_on_ui_close = false;
        save_on_change = true;
      };
    };
  };

  # ── Flash: enhanced search motion ─────────────────────
  plugins.flash = {
    enable = true;
    settings = {
      modes = {
        search = {
          enabled = true;
        };
        char = {
          enabled = true;
          multi_labels = true;
        };
      };
      labels = "abcdefghijklmnopqrstuvwxyz";
    };
  };

  # ── NvimTree: file explorer ───────────────────────────
  plugins.nvim-tree = {
    enable = true;
    settings = {
      disable_netrw = true;
      hijack_netrw = true;
      hijack_cursor = true;
      hijack_unnamed_buffer_when_opening = false;
      sync_root_with_cwd = true;
      respect_buf_cwd = true;
      update_focused_file = {
        enable = true;
        update_root = true;
      };
      view = {
        width = 35;
        side = "left";
        preserve_window_proportions = true;
        number = false;
        relativenumber = false;
        signcolumn = "yes";
      };
      renderer = {
        add_trailing = false;
        group_empty = true;
        highlight_git = true;
        full_name = false;
        highlight_opened_files = "name";
        root_folder_modifier = ":t";
        indent_width = 2;
        indent_markers = {
          enable = true;
          inline_arrows = true;
          icons = {
            corner = "└";
            edge = "│";
            item = "│";
            bottom = "─";
            none = " ";
          };
        };
        icons = {
          glyphs = {
            default = "";
            symlink = "";
            bookmark = "";
            folder = {
              arrow_closed = "";
              arrow_open = "";
              default = "";
              open = "";
              empty = "";
              empty_open = "";
              symlink = "";
              symlink_open = "";
            };
            git = {
              unstaged = "";
              staged = "S";
              unmerged = "";
              renamed = "";
              untracked = "";
              deleted = "";
              ignored = "◌";
            };
          };
          show = {
            git = true;
            folder = true;
            file = true;
            folder_arrow = true;
          };
        };
        special_files = {
          "Cargo.toml" = { };
          "Makefile" = { };
          "README.md" = { };
          "flake.nix" = { };
          "package.json" = { };
        };
        symlink_destination = true;
      };
      filters = {
        dotfiles = false;
        custom = [
          "^.git$"
          "^.direnv$"
          "^result$"
          "^target$"
          "^node_modules$"
        ];
        exclude = [ ];
      };
      actions = {
        open_file = {
          resize_window = true;
          window_picker = {
            enable = true;
            picker = "default";
            chars = "abcdefghijklmnopqrstuvwxyz";
          };
        };
      };
      trash = {
        cmd = "trash";
      };
      log = {
        enable = false;
        truncate = false;
        types = [
          "diagnostics"
          "git"
          "profile"
        ];
      };
    };
  };
}
