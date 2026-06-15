# modules/ui.nix
# UI enhancements: statusline, dashboard, which-key, noice, indent guides, dressing.
{ ... }:
{
  # ── Which-key: keybinding popup ─────────────────────────
  plugins.which-key = {
    enable = true;
    settings = {
      icons = {
        mappings = false;
        group = "";
      };
      spec = [
        {
          __unkeyed-1 = "<leader>";
          group = "Satanic Vim";
          icon = " ";
        }
        {
          __unkeyed-1 = "<leader>f";
          group = "Find";
          icon = " ";
        }
        {
          __unkeyed-1 = "<leader>g";
          group = "Git";
          icon = " ";
        }
        {
          __unkeyed-1 = "<leader>l";
          group = "LSP";
          icon = " ";
        }
        {
          __unkeyed-1 = "<leader>t";
          group = "Tab / Terminal";
          icon = " ";
        }
        {
          __unkeyed-1 = "<leader>h";
          group = "Harpoon";
          icon = " ";
        }
        {
          __unkeyed-1 = "<leader>x";
          group = "Trouble / Diagnostics";
          icon = " ";
        }
        {
          __unkeyed-1 = "<leader>m";
          group = "Molten / Maximize";
          icon = " ";
        }
        {
          __unkeyed-1 = "<leader>h";
          group = "Hunk / Harpoon";
          icon = " ";
        }
      ];
    };
  };

  # ── Lualine: statusline ────────────────────────────────
  plugins.lualine = {
    enable = true;
    settings = {
      options = {
        theme = "auto";
        component_separators = {
          left = "";
          right = "";
        };
        section_separators = {
          left = "";
          right = "";
        };
        globalstatus = true;
        refresh = {
          statusline = 100;
          tabline = 100;
          winbar = 100;
        };
        disabled_filetypes = {
          statusline = [ "alpha" ];
          winbar = [ "alpha" ];
        };
      };
      sections = {
        lualine_a = [ "mode" ];
        lualine_b = [
          "branch"
          "diff"
          {
            __unkeyed = "diagnostics";
            sources = [ "nvim_diagnostic" ];
            symbols = {
              error = " ";
              warn = " ";
              info = " ";
              hint = " ";
            };
          }
        ];
        lualine_c = [
          {
            __unkeyed = "filename";
            path = 1;
            symbols = {
              modified = " ●";
              readonly = " ";
              unnamed = " No Name";
              newfile = " ";
            };
          }
        ];
        lualine_x = [
          "filetype"
          {
            __unkeyed = "encoding";
            fmt = ''
              function(str)
                if str == "utf-8" then return "" end
                return str
              end
            '';
          }
          "filesize"
        ];
        lualine_y = [ "progress" ];
        lualine_z = [
          {
            __unkeyed = "location";
            fmt = ''
              function(str)
                return " " .. str
              end
            '';
          }
        ];
      };
      inactive_sections = {
        lualine_a = [ ];
        lualine_b = [ ];
        lualine_c = [ "filename" ];
        lualine_x = [ "location" ];
        lualine_y = [ ];
        lualine_z = [ ];
      };
      tabline = { };
      winbar = { };
      inactive_winbar = { };
      extensions = [
        "fugitive"
        "neo-tree"
        "nvim-tree"
        "quickfix"
        "trouble"
      ];
    };
  };

  # ── Alpha: dashboard / startup screen ──────────────────
  plugins.alpha = {
    enable = true;
    settings.layout = [
      { type = "padding"; val = 2; }
      {
        type = "text";
        val = [
          "  ███████╗ █████╗ ████████╗ █████╗ ███╗   ██╗██╗ ██████╗    ██╗   ██╗██╗███╗   ███╗"
          "  ██╔════╝██╔══██╗╚══██╔══╝██╔══██╗████╗  ██║██║██╔════╝    ██║   ██║██║████╗ ████║"
          "  ███████╗███████║   ██║   ███████║██╔██╗ ██║██║██║         ██║   ██║██║██╔████╔██║"
          "  ╚════██║██╔══██║   ██║   ██╔══██║██║╚██╗██║██║██║         ╚██╗ ██╔╝██║██║╚██╔╝██║"
          "  ███████║██║  ██║   ██║   ██║  ██║██║ ╚████║██║╚██████╗     ╚████╔╝ ██║██║ ╚═╝ ██║"
          "  ╚══════╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝ ╚═════╝     ╚═══╝  ╚═╝╚═╝     ╚═╝"
          ""
          "                          ██╗   ██╗██╗███╗   ███╗"
          "                          ██║   ██║██║████╗ ████║"
          "                          ██║   ██║██║██╔████╔██║"
          "                          ╚██╗ ██╔╝██║██║╚██╔╝██║"
          "                           ╚████╔╝ ██║██║ ╚═╝ ██║"
          "                            ╚═══╝  ╚═╝╚═╝     ╚═╝"
        ];
        opts = { position = "center"; hl = "AlphaHeader"; };
      }
      { type = "padding"; val = 2; }
      {
        type = "group";
        val = [
          {
            type = "button";
            val = "  Find File";
            on_press.__raw = "function() require('telescope.builtin').find_files() end";
            opts = {
              keymap = [ "n" "f" "<Cmd>Telescope find_files<CR>" { } ];
              shortcut = "f";
              position = "center";
              width = 50;
              align_shortcut = "right";
              hl = "AlphaButtons";
              hl_shortcut = "AlphaShortcut";
            };
          }
          {
            type = "button";
            val = "  Recent Files";
            on_press.__raw = "function() require('telescope.builtin').oldfiles() end";
            opts = {
              keymap = [ "n" "r" "<Cmd>Telescope oldfiles<CR>" { } ];
              shortcut = "r";
              position = "center";
              width = 50;
              align_shortcut = "right";
              hl = "AlphaButtons";
              hl_shortcut = "AlphaShortcut";
            };
          }
          {
            type = "button";
            val = "  Live Grep";
            on_press.__raw = "function() require('telescope.builtin').live_grep() end";
            opts = {
              keymap = [ "n" "g" "<Cmd>Telescope live_grep<CR>" { } ];
              shortcut = "g";
              position = "center";
              width = 50;
              align_shortcut = "right";
              hl = "AlphaButtons";
              hl_shortcut = "AlphaShortcut";
            };
          }
          {
            type = "button";
            val = "  Neogit";
            on_press.__raw = "function() require('neogit').open() end";
            opts = {
              keymap = [ "n" "n" "<Cmd>Neogit<CR>" { } ];
              shortcut = "n";
              position = "center";
              width = 50;
              align_shortcut = "right";
              hl = "AlphaButtons";
              hl_shortcut = "AlphaShortcut";
            };
          }
          {
            type = "button";
            val = "  Quit";
            on_press.__raw = "function() vim.cmd.qa() end";
            opts = {
              keymap = [ "n" "q" "<Cmd>qa<CR>" { } ];
              shortcut = "q";
              position = "center";
              width = 50;
              align_shortcut = "right";
              hl = "AlphaButtons";
              hl_shortcut = "AlphaShortcut";
            };
          }
        ];
      }
      { type = "padding"; val = 2; }
    ];
  };

  # ── Noice ──────────────────────────────────────────────
  plugins.noice = {
    enable = true;
    settings = {
      cmdline = {
        enabled = true;
        view = "cmdline_popup";
        opts = {
          position = {
            row = "50%";
            col = "50%";
          };
          size = {
            width = 60;
            height = "auto";
          };
          border = {
            style = "rounded";
            padding = [
              0
              1
            ];
          };
          win_options = {
            winhighlight = "NormalFloat:NormalFloat,FloatBorder:FloatBorder";
          };
        };
        format = {
          cmdline = {
            pattern = "^:";
            icon = " ";
            lang = "vim";
          };
          search_down = {
            pattern = "^/";
            icon = " ";
            lang = "regex";
          };
          search_up = {
            pattern = "^?";
            icon = " ";
            lang = "regex";
          };
          filter = {
            pattern = ":%s/";
            icon = " ";
            lang = "regex";
          };
          lua = {
            pattern = "^:lua";
            icon = " ";
            lang = "lua";
          };
          help = {
            pattern = "^:h";
            icon = " ";
            lang = "vim";
          };
          input = {
            view = "cmdline_input";
          };
        };
      };
      messages = {
        enabled = true;
        view = "mini";
        view_error = "mini";
        view_warn = "mini";
      };
      popupmenu = {
        enabled = true;
        backend = "nui";
      };
      redirect = {
        view = "popup";
        filter = {
          event = "msg_show";
        };
      };
      lsp = {
        progress = {
          enabled = true;
          format = "lsp";
          format_done = "lsp";
          throttle = 200;
          view = "mini";
        };
        override = {
          "vim.lsp.util.convert_input_to_markdown_lines" = true;
          "vim.lsp.util.stylize_markdown" = true;
          "cmp.entry.get_documentation" = true;
        };
        hover = {
          enabled = true;
          view = "hover";
          silent = false;
        };
        signature = {
          enabled = true;
          auto_open = {
            enabled = true;
            trigger = true;
            luasnip = true;
            throttle = 50;
          };
          view = "hover";
        };
      };
      throttle = 50;
      smart_move = {
        enabled = true;
        keymaps = {
          "<S-h>" = [
            "prev"
            "cmdline_popup"
          ];
          "<S-l>" = [
            "next"
            "cmdline_popup"
          ];
        };
      };
      presets = {
        bottom_search = false;
        command_palette = true;
        long_message_to_split = true;
        inc_rename = true;
        lsp_doc_border = true;
      };
      views = {
        mini = {
          win_options = {
            winhighlight = "Normal:NormalFloat";
          };
        };
        hover = {
          border = "rounded";
          win_options = {
            winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder";
          };
        };
      };
    };
  };

  # ── Indent-blankline ──────────────────────────────────
  plugins.indent-blankline = {
    enable = true;
    settings = {
      indent = {
        char = "▏";
        smart_indent_cap = true;
        priority = 1;
      };
      whitespace = {
        highlight = [ "Whitespace" ];
        remove_blankline_trail = false;
      };
      scope = {
        enabled = true;
        show_start = false;
        show_end = false;
      };
      exclude = {
        filetypes = [
          "alpha"
          "help"
          "lspinfo"
          "TelescopePrompt"
          "Trouble"
          "toggleterm"
          "lazy"
          "mason"
          "nvim-tree"
          "neo-tree"
          "NeogitStatus"
          "NvimTree"
          "Outline"
        ];
      };
    };
  };

  # ── Dressing ──────────────────────────────────────────
  plugins.dressing = {
    enable = true;
    settings = {
      input = {
        enabled = true;
        default_prompt = " ";
        title_pos = "center";
        border = "rounded";
        relative = "editor";
        prefer_width = 40;
        max_width = [
          80
          0.8
        ];
        min_width = [
          20
          0.2
        ];
      };
      select = {
        enabled = true;
        backend = [
          "telescope"
          "builtin"
        ];
        telescope = {
          win_options = {
            winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder";
          };
        };
        builtin = {
          win_options = {
            winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder";
          };
        };
      };
    };
  };

  # ── Notify ────────────────────────────────────────────
  plugins.notify = {
    enable = true;
    settings = {
      animate = true;
      background_colour = "#0a0a0f";
      fps = 60;
      icons = {
        debug = " ";
        error = " ";
        info = " ";
        trace = "✎ ";
        warn = " ";
      };
      level = 2;
      minimum_width = 50;
      render = "default";
      stages = "fade_in_slide_out";
      time_formats = {
        before = "· ";
        after = "· ";
      };
      top_down = true;
    };
  };

  # ── Extra UI highlights for our theme ──────────────────
  extraConfigLua = ''
    -- ── Custom highlight groups for satanic theme ────────
    local function setup_satanic_highlights()
      local hl = vim.api.nvim_set_hl

      hl(0, "CursorLine",   { bg = "#1a0a0f" })
      hl(0, "CursorColumn", { bg = "#1a0a0f" })
      hl(0, "LineNr",       { fg = "#4a3a4a", bg = "#0a0a0f" })
      hl(0, "CursorLineNr", { fg = "#c12127", bg = "#0a0a0f", bold = true })
      hl(0, "Visual",       { bg = "#3a1a2a", fg = "#d4c5d4" })
      hl(0, "Search",       { fg = "#0a0a0f", bg = "#d4a84b" })
      hl(0, "IncSearch",    { fg = "#0a0a0f", bg = "#e8743c" })
      hl(0, "CurSearch",    { fg = "#0a0a0f", bg = "#e63946" })
      hl(0, "MatchParen",   { fg = "#d4a84b", bg = "#14101a", bold = true, underline = true })
      hl(0, "DiagnosticSignError", { fg = "#c12127", bg = "#0a0a0f" })
      hl(0, "DiagnosticSignWarn",  { fg = "#e8743c", bg = "#0a0a0f" })
      hl(0, "DiagnosticSignInfo",  { fg = "#4a9c9c", bg = "#0a0a0f" })
      hl(0, "DiagnosticSignHint",  { fg = "#7a4a8a", bg = "#0a0a0f" })
      hl(0, "FloatBorder",  { fg = "#4a3a4a", bg = "#14101a" })
      hl(0, "NormalFloat",  { bg = "#14101a" })
      hl(0, "NormalSB",     { bg = "#14101a" })
      hl(0, "TelescopeSelection",      { fg = "#d4c5d4", bg = "#3a1a2a" })
      hl(0, "TelescopeSelectionCaret", { fg = "#c12127", bg = "#3a1a2a" })
      hl(0, "TelescopeMultiSelection", { fg = "#e63946", underline = true })
      hl(0, "TelescopeNormal",         { bg = "#14101a" })
      hl(0, "TelescopeBorder",         { fg = "#4a3a4a", bg = "#14101a" })
      hl(0, "TelescopePromptBorder",   { fg = "#c12127", bg = "#14101a" })
      hl(0, "TelescopeResultsTitle",   { fg = "#d4a84b" })
      hl(0, "TelescopePromptTitle",    { fg = "#c12127" })
      hl(0, "TelescopePreviewTitle",   { fg = "#d4a84b" })
      hl(0, "WhichKey",           { fg = "#c12127", bold = true })
      hl(0, "WhichKeyGroup",      { fg = "#d4a84b" })
      hl(0, "WhichKeyDesc",       { fg = "#d4c5d4" })
      hl(0, "WhichKeySeparator",  { fg = "#4a3a4a" })
      hl(0, "WhichKeyFloat",      { bg = "#14101a" })
      hl(0, "WhichKeyBorder",     { fg = "#4a3a4a", bg = "#14101a" })
      hl(0, "NoiceCmdlinePopupTitle",   { fg = "#c12127", bold = true })
      hl(0, "NoiceCmdlinePopupBorder",  { fg = "#4a3a4a" })
      hl(0, "AlphaHeader",   { fg = "#c12127", bold = true })
      hl(0, "AlphaShortcut", { fg = "#d4a84b", bold = true })
      hl(0, "AlphaFooter",   { fg = "#4a3a4a", italic = true })
      hl(0, "AlphaButtons",  { fg = "#d4c5d4" })
      hl(0, "NvimTreeNormal",           { bg = "#0a0a0f" })
      hl(0, "NvimTreeVertSplit",        { fg = "#14101a", bg = "#14101a" })
      hl(0, "NvimTreeFolderIcon",       { fg = "#d4a84b" })
      hl(0, "NvimTreeGitDirty",         { fg = "#e8743c" })
      hl(0, "NvimTreeGitStaged",        { fg = "#4a9c6f" })
      hl(0, "NvimTreeGitNew",           { fg = "#4a9c6f" })
      hl(0, "NvimTreeGitDeleted",       { fg = "#c12127" })
      hl(0, "NvimTreeOpenedFolderName", { fg = "#c12127", bold = true })
      hl(0, "NvimTreeCursorLine",       { bg = "#1a1420" })
      hl(0, "GitSignsAdd",    { fg = "#4a9c6f" })
      hl(0, "GitSignsChange",  { fg = "#d4a84b" })
      hl(0, "GitSignsDelete", { fg = "#c12127" })
      hl(0, "IblIndent",           { fg = "#1a1420" })
      hl(0, "IblScope",            { fg = "#2a1a2a" })
      hl(0, "TroubleNormal",  { bg = "#0a0a0f" })
      hl(0, "ToggleTerm1Normal", { bg = "#0a0a0f" })
      hl(0, "ToggleTerm1Border", { fg = "#4a3a4a", bg = "#0a0a0f" })
      hl(0, "TodoFgTODO",  { fg = "#c12127", bold = true })
      hl(0, "TodoBgTODO",  { fg = "#0a0a0f", bg = "#c12127" })
      hl(0, "TodoFgFIX",   { fg = "#e63946", bold = true })
      hl(0, "TodoBgFIX",   { fg = "#0a0a0f", bg = "#e63946" })
      hl(0, "TodoFgHACK",  { fg = "#d4a84b", bold = true })
      hl(0, "TodoBgHACK",  { fg = "#0a0a0f", bg = "#d4a84b" })
      hl(0, "TodoFgNOTE",  { fg = "#4a9c9c", bold = true })
      hl(0, "TodoBgNOTE",  { fg = "#0a0a0f", bg = "#4a9c9c" })
      hl(0, "DiffAdd",    { bg = "#0a1a0a", fg = "#4a9c6f" })
      hl(0, "DiffChange", { bg = "#1a0a0f", fg = "#d4a84b" })
      hl(0, "DiffDelete", { bg = "#1a0a0a", fg = "#c12127" })
      hl(0, "DiffText",   { bg = "#2a1a2a", fg = "#e63946" })
    end

    setup_satanic_highlights()
  '';
}
