{ config, lib, pkgs, ... }:

{
  programs = {
    nixvim = {
      enable = true;

      # Move all configuration options to the top level instead of using a config block
      # Basic options
      opts = {
        number = true;         # Show line numbers
        relativenumber = true; # Show relative line numbers
        shiftwidth = 2;        # Number of spaces per indentation
        tabstop = 2;           # Number of spaces a TAB counts for
      };

      # Colorscheme configuration :cite[1]:cite[7]
      colorschemes.base16= {
        enable = true;
#        settings = {
#        };
      };

      # Plugin configuration
      plugins = {
        # Web devicons :cite[2]:cite[10]
        web-devicons = {
          enable = true;
          settings = {
            color_icons = true;
            default = true;
            strict = true;
          };
        };

        # GitHub Copilot :cite[5]
        copilot-chat = {
          enable = true;
          settings = {
            panel = {
              enabled = true;
              auto_refresh = true;
            };
            suggestion = {
              enabled = true;
              auto_trigger = true;
              debounce = 75;
            };
            filetypes = {
              yaml = false;
              markdown = false;
              help = false;
              gitcommit = false;
              gitrebase = false;
            };
          };
        };

        # LSP configuration :cite[4]:cite[6]
        lsp = {
          enable = true;
          servers = {
            nixd.enable = true;
            nil_ls.enable = false;
            rust_analyzer.enable = false;
            ts_ls.enable = false;
            pyright.enable = true;
          };
        };
        # Completion framework :cite[5]
        cmp = {
          enable = true;
          settings = {
            sources = [
              { name = "nvim_lsp"; priority = 100; }
              { name = "copilot"; priority = 50; } # Copilot as completion source
              { name = "buffer"; priority = 25; }
            ];
            mapping = {
              "<Tab>" = "cmp.mapping.select_next_item()";
              "<S-Tab>" = "cmp.mapping.select_prev_item()";
              "<CR>" = "cmp.mapping.confirm({ select = false })";
            };
          };
        };

        # Tree-sitter for better syntax highlighting :cite[6]
        treesitter = {
          enable = true;
          settings = {
            ensure_installed = ["nix" "rust" "python" "javascript" "lua"];
          };
        };

        # Telescope for fuzzy finding :cite[6]
        telescope.enable = true;

        # Which-key for keybinding hints :cite[6]
        which-key.enable = true;

        # Automatically close pairs of brackets, quotes, etc. :cite[6]
        nvim-autopairs.enable = true;
      };

      # Key mappings :cite[5]:cite[6]
      keymaps = [
        {
          key = "<leader>G";
          action = ":lua _G.cmp_source_toggle = not _G.cmp_source_toggle; _G.setup_cmp()<CR>";
          options = {
            noremap = true;
            silent = true;
          };
        }
        {
          key = "<space>e";
          action = ":NvimTreeToggle<CR>";
          options = {
            noremap = true;
            silent = true;
          };
        }
      ];

      # Extra configuration for Copilot integration :cite[5]
      extraConfigLua = ''
        -- Copilot toggle function
        _G.cmp_source_toggle = false
        _G.cmp_source_first_run = true

        _G.setup_cmp = function()
          local sources

          if _G.cmp_source_toggle then
            sources = {
              { name = 'nvim_lsp', priority = 100 },
              { name = 'copilot', priority = 50 },
              { name = 'buffer', priority = 25 },
            }
          else
            sources = {
              { name = 'nvim_lsp', priority = 100 },
              { name = 'buffer', priority = 25 },
            }
          end

          require('cmp').setup({
            sources = require('cmp').config.sources(sources)
          })

          if _G.cmp_source_first_run then
            _G.cmp_source_first_run = false
            return
          end

          local message = _G.cmp_source_toggle and "nvim-cmp Copilot enabled" or "nvim-cmp Copilot disabled"
          vim.api.nvim_echo({ { message, "Normal" } }, false, {})
        end

        -- Initial setup
        _G.setup_cmp()
      '';
    };

    zsh = {
      enable = true;
      enableCompletion = true;
      enableFastSyntaxHighlighting = true;
      enableFzfCompletion = true;
      enableFzfGit = true;
      enableFzfHistory = true;
      enableGlobalCompInit = true;
    };
    direnv = {
      enable = true;
    };
    vim = {
      enable = true;
      enableSensible = true;
    };
    nix-index = {
      enable = true;
    };
  };
}
