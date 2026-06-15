# modules/tools.nix
# Developer tools: terminal, diagnostics, undo tree, colors, maximizer.
{ ... }:
{
  # ── ToggleTerm: floating terminal ──────────────────────
  plugins.toggleterm = {
    enable = true;
    settings = {
      size = 20;
      open_mapping = "[[<leader>tt]]";
      hide_numbers = true;
      shade_filetypes = { };
      shade_terminals = true;
      shading_factor = 2;
      start_in_insert = true;
      insert_mappings = true;
      persist_size = true;
      direction = "horizontal";
      close_on_exit = true;
      shell = "zsh";
      float_opts = {
        border = "curved";
        winblend = 3;
        highlights = {
          border = "Normal";
          background = "Normal";
        };
      };
      highlights = {
        Normal = {
          guibg = "#0a0a0f";
        };
        NormalFloat = {
          link = "Normal";
        };
        FloatBorder = {
          guifg = "#4a3a4a";
          guibg = "#0a0a0f";
        };
      };
    };
  };

  # ── Trouble: diagnostics list ──────────────────────────
  plugins.trouble = {
    enable = true;
    settings = {
      mode = "diagnostics";
      auto_open = false;
      auto_close = false;
      auto_preview = true;
      auto_fold = false;
      auto_jump = false;
      throttle = 200;
      focus = false;
      follow = true;
      indent_lines = true;
      icons = { };
      use_diagnostic_signs = true;
      multiline = true;
      separator = "─";
      win_config = {
        position = "right";
        size = 0.3;
      };
      groups = [
        {
          group = "diagnostics";
          name = "Diagnostics";
        }
        {
          group = "workspace_diagnostics";
          name = "Workspace";
        }
        {
          group = "document_diagnostics";
          name = "Document";
        }
        {
          group = "quickfix";
          name = "Quickfix";
        }
        {
          group = "lsp_references";
          name = "References";
        }
        {
          group = "lsp_definitions";
          name = "Definitions";
        }
        {
          group = "lsp_type_definitions";
          name = "Type Definitions";
        }
        {
          group = "lsp_implementations";
          name = "Implementations";
        }
      ];
    };
  };

  # ── Undotree: visual undo history ──────────────────────
  plugins.undotree = {
    enable = true;
    settings = {
      auto_open_diff = true;
      diffpanel_height = 8;
      focus_on_toggle = true;
      highlight_changed_text = true;
      short_heading = false;
      split = "left";
      window_layout = "left";
      window_width = 40;
    };
  };

  # ── Colorizer: color hex preview ───────────────────────
  plugins.colorizer = {
    enable = true;
    settings = {
      user_default_options = {
        RGB = true;
        RRGGBB = true;
        names = false;
        RRGGBBAA = true;
        AARRGGBB = true;
        rgb_fn = true;
        hsl_fn = true;
        css = true;
        css_fn = true;
        mode = "foreground";
        tailwind = true;
        sass = {
          enable = false;
        };
        virtualtext = "■";
      };
      buftypes = [ "*" ];
      filetypes = {
        "*" = {
          RGB = true;
          RRGGBB = true;
        };
      };
    };
  };

  # ── Vim-maximizer: maximize/restore splits ────────────

  # ── Suda: sudo write (uses built-in :w !sudo tee %) ────

  # ── Neotest: test runner (disabled; needs adapter packages) ─

  # ── Jupytext: Jupyter notebook sync ────────────────────
  plugins.jupytext = {
    enable = true;
    settings = {
      output_extension = "py";
      style = "hydrogen";
      custom_language_formatting = {
        python = {
          extension = "py";
          style = "hydrogen";
        };
      };
    };
  };

  # ── Molten: Jupyter kernels in Neovim ──────────────────
  plugins.molten = {
    enable = true;
    settings = {
      auto_open_output = false;
      image_provider = "none";
      output_win_max_height = 20;
      wrap_output = true;
      virt_text_output = true;
      output_win_cover_gutter = true;
      output_win_hide_on_leave = true;
      output_crop_border = true;
    };
  };

  # ── Vimtex: LaTeX support (disabled on macOS; needs zathura/skim) ─

  # ── Markdown preview ───────────────────────────────────
  plugins.markdown-preview = {
    enable = true;
  };
}
