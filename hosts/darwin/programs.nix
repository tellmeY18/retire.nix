{ pkgs
, ...
}:

let
  jupytextPkg = pkgs.python3Packages.jupytext;
  # You don't need a separate moltenPythonDeps variable anymore
  # NixVim handles this through the plugin's python3Dependencies option
in
{
  environment.systemPackages = [
    jupytextPkg
  ];

  # Set environment variable for Jupyter runtime directory
  environment.variables = {
    JUPYTER_RUNTIME_DIR = "$HOME/.cache/jupyter/runtime";
  };

  programs = {
    nixvim = {
      enable = true;

      # Basic options
      opts = {
        number = true;
        relativenumber = true;
        shiftwidth = 2;
        tabstop = 2;
      };

      # Colorscheme configuration
      colorschemes.base16 = {
        enable = true;
      };

      # Plugin configuration
      plugins = {
        # Web devicons
        web-devicons = {
          enable = true;
          settings = {
            color_icons = true;
            default = true;
            strict = true;
          };
        };

        # GitHub Copilot
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

        # LSP configuration
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

        # Completion framework
        cmp = {
          enable = true;
          settings = {
            sources = [
              {
                name = "nvim_lsp";
                priority = 100;
              }
              {
                name = "copilot";
                priority = 50;
              }
              {
                name = "buffer";
                priority = 25;
              }
            ];
            mapping = {
              "<Tab>" = "cmp.mapping.select_next_item()";
              "<S-Tab>" = "cmp.mapping.select_prev_item()";
              "<CR>" = "cmp.mapping.confirm({ select = false })";
            };
          };
        };

        # Tree-sitter for better syntax highlighting
        treesitter = {
          enable = true;
          settings = {
            ensure_installed = [
              "nix"
              "rust"
              "python"
              "javascript"
              "lua"
            ];
          };
        };

        # Molten - The proper NixVim way
        molten = {
          enable = true;

          # This is the correct way to add Python dependencies in NixVim
          python3Dependencies =
            p: with p; [
              pynvim
              jupyter-client
              cairosvg
              ipython
              nbformat
              ipykernel
            ];

          # Molten settings
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

        # Telescope for fuzzy finding
        telescope.enable = true;

        # Which-key for keybinding hints
        which-key.enable = true;

        # Automatically close pairs of brackets, quotes, etc.
        nvim-autopairs.enable = true;

        # Jupytext for Jupyter notebook support
        jupytext = {
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
          python3Dependencies =
            p: with p; [
              jupytext
            ];
        };
      };

      # Key mappings
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
        # Molten keybindings
        {
          key = "<leader>mi";
          action = ":MoltenInit<CR>";
          options = {
            noremap = true;
            silent = true;
            desc = "Initialize Molten";
          };
        }
        {
          key = "<leader>me";
          action = ":MoltenEvaluateOperator<CR>";
          options = {
            noremap = true;
            silent = true;
            desc = "Evaluate operator";
          };
        }
        {
          key = "<leader>ml";
          action = ":MoltenEvaluateLine<CR>";
          options = {
            noremap = true;
            silent = true;
            desc = "Evaluate line";
          };
        }
        {
          key = "<leader>mr";
          action = ":MoltenReevaluateCell<CR>";
          options = {
            noremap = true;
            silent = true;
            desc = "Re-evaluate cell";
          };
        }
        {
          key = "<leader>mv";
          mode = "v";
          action = ":<C-u>MoltenEvaluateVisual<CR>gv";
          options = {
            noremap = true;
            silent = true;
            desc = "Evaluate visual selection";
          };
        }
      ];

      # Extra configuration
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

        -- Set Jupyter runtime directory and create it
        local jupyter_runtime = vim.fn.expand("$HOME/.cache/jupyter/runtime")
        vim.fn.mkdir(jupyter_runtime, "p")
        vim.env.JUPYTER_RUNTIME_DIR = jupyter_runtime
      '';
    };

    vim = {
      enable = true;
      enableSensible = true;
    };
  };
}
