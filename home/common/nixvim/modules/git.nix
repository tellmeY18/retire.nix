# modules/git.nix
# Git integration: gitsigns, neogit, diffview.
{ ... }:
{
  # ── Gitsigns: git signs in gutter ──────────────────────
  plugins.gitsigns = {
    enable = true;
    settings = {
      signs = {
        add = {
          text = "▎";
        };
        change = {
          text = "▎";
        };
        delete = {
          text = " ";
        };
        topdelete = {
          text = " ";
        };
        changedelete = {
          text = "▎";
        };
        untracked = {
          text = "▎";
        };
      };
      signs_staged = {
        add = {
          text = "▎";
        };
        change = {
          text = "▎";
        };
        delete = {
          text = " ";
        };
        topdelete = {
          text = " ";
        };
        changedelete = {
          text = "▎";
        };
      };
      signcolumn = true;
      numhl = false;
      linehl = false;
      word_diff = false;
      watch_gitdir = {
        interval = 1000;
        follow_files = true;
      };
      attach_to_untracked = true;
      current_line_blame = true;
      current_line_blame_opts = {
        virt_text = true;
        virt_text_pos = "eol";
        delay = 500;
        ignore_whitespace = false;
      };
      current_line_blame_formatter = "    <author>, <author_time:%Y-%m-%d>  •  <summary>";
      sign_priority = 6;
      update_debounce = 200;
      status_formatter = null;
      max_file_length = 40000;
      preview_config = {
        border = "rounded";
        col = 1;
        row = 1;
        relative = "cursor";
        style = "minimal";
        winblend = 0;
      };
      on_attach = ''
        function(bufnr)
          local gitsigns = require('gitsigns')
          local map = function(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc, noremap = true, silent = true })
          end

          -- Navigation
          map('n', ']c', function()
            if vim.wo.diff then return ']c' end
            gitsigns.next_hunk()
          end, 'Next hunk')

          map('n', '[c', function()
            if vim.wo.diff then return '[c' end
            gitsigns.prev_hunk()
          end, 'Prev hunk')

          -- Actions
          map({ 'n', 'v' }, '<leader>hs', gitsigns.stage_hunk, 'Stage hunk')
          map({ 'n', 'v' }, '<leader>hr', gitsigns.reset_hunk, 'Reset hunk')
          map('n', '<leader>hS', gitsigns.stage_buffer, 'Stage buffer')
          map('n', '<leader>hu', gitsigns.undo_stage_hunk, 'Undo stage hunk')
          map('n', '<leader>hR', gitsigns.reset_buffer, 'Reset buffer')
          map('n', '<leader>hp', gitsigns.preview_hunk, 'Preview hunk')
          map('n', '<leader>hb', function() gitsigns.blame_line({ full = true }) end, 'Blame line')
          map('n', '<leader>hd', gitsigns.diffthis, 'Diff this')
          map('n', '<leader>hD', function() gitsigns.diffthis('~') end, 'Diff this ~')
          map('n', '<leader>ht', gitsigns.toggle_current_line_blame, 'Toggle blame')
          map('n', '<leader>hT', gitsigns.toggle_signs, 'Toggle signs')
          map('n', '<leader>hq', gitsigns.setqflist, 'Quickfix')
        end
      '';
    };
  };

  # ── Neogit: Magit-like Git interface ───────────────────
  plugins.neogit = {
    enable = true;
    settings = {
      disable_signs = false;
      disable_context_highlighting = false;
      disable_commit_confirmation = false;
      remember_settings = true;
      use_magit_keybindings = false;
      graph_style = "unicode";
      integrations = {
        diffview = true;
        telescope = true;
      };
      kind = "tab";
      # Use default section visibility
      mappings = {
        status = {
          X = "Discard";
        };
      };
    };
  };

  # ── Diffview: side-by-side diff viewer ─────────────────
  plugins.diffview = {
    enable = true;
    settings = {
      enhanced_diff_hl = true;
      git_cmd = [ "git" ];
      use_icons = true;
      show_help_hints = false;
      watch_index = true;
      icons = {
        folder_closed = "";
        folder_open = "";
      };
      sign = {
        fold_closed = "";
        fold_open = "";
      };
      file_panel = {
        listing_style = "tree";
        tree_options = {
          flatten_dirs = true;
          folder_status = "";
        };
        win_config = {
          position = "bottom";
          height = 12;
        };
      };
      view = {
        merge_tool = {
          layout = "diff3_mixed";
          win_config = {
            "1" = {
              position = "left";
              size = 0.33;
            };
            "2" = {
              position = "left";
              size = 0.33;
            };
            "3" = {
              position = "left";
              size = 0.33;
            };
          };
        };
      };
    };
  };
}
