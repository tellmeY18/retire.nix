# modules/lsp.nix
# LSP servers, formatting via conform, linting.
{ ... }:
{
  # ── LSP configuration ──────────────────────────────────
  plugins.lsp = {
    enable = true;

    keymaps = {
      silent = true;
      diagnostic = {
        "<leader>ld" = "open_float";
        "[d" = "goto_prev";
        "]d" = "goto_next";
        "<leader>lq" = "setloclist";
      };
      lspBuf = {
        "gd" = "declaration";
        "gD" = "definition";
        "K" = "hover";
        "gi" = "implementation";
        "gt" = "type_definition";
        "gr" = "references";
        "<leader>ca" = "code_action";
        "<leader>rn" = "rename";
      };
    };

    servers = {
      # Nix
      nixd = {
        enable = true;
        settings = {
          nixpkgs = {
            expr = "import <nixpkgs> { }";
          };
          formatting = {
            command = [ "nixpkgs-fmt" ];
          };
        };
      };
      # Rust
      rust_analyzer = {
        enable = true;
        installCargo = false;
        installRustc = false;
        settings = {
          check = {
            command = "clippy";
          };
          inlayHints = {
            typeHints = true;
            parameterHints = true;
            chainingHints = true;
          };
        };
      };

      # Python
      pyright = {
        enable = true;
        settings = {
          python = {
            analysis = {
              autoSearchPaths = true;
              useLibraryCodeForTypes = true;
              diagnosticMode = "workspace";
              typeCheckingMode = "basic";
            };
          };
        };
      };

      # Lua
      lua_ls = {
        enable = true;
        settings = {
          Lua = {
            runtime.version = "LuaJIT";
            diagnostics.globals = [ "vim" ];
            workspace.checkThirdParty = false;
            telemetry.enable = false;
          };
        };
      };

      # TypeScript / JavaScript
      ts_ls = {
        enable = true;
        settings = {
          format = {
            indentSize = 2;
            tabSize = 2;
          };
        };
      };

      # JSON
      jsonls = {
        enable = true;
        settings = {
          format = {
            enable = true;
          };
        };
      };

      # YAML
      yamlls = {
        enable = true;
        settings = {
          yaml = {
            format.enable = true;
            keyOrdering = false;
            schemaStore = {
              enable = true;
              url = "https://www.schemastore.org/api/json/catalog.json";
            };
          };
        };
      };

      # Docker
      dockerls.enable = true;

      # Markdown
      marksman.enable = true;

      # TOML
      taplo.enable = true;

      # Bash
      bashls.enable = true;

      # MATLAB
      matlab_ls.enable = true;
    };
  };

  # ── Conform: auto-formatting on save ───────────────────
  plugins.conform-nvim = {
    enable = true;
    settings = {
      formatters_by_ft = {
        lua = [ "stylua" ];
        nix = [ "nixpkgs-fmt" ];
        python = [
          "isort"
          "black"
        ];
        rust = [ "rustfmt" ];
        json = [ "fixjson" ];
        yaml = [ "yamlfmt" ];
        toml = [ "taplo" ];
        sh = [ "shfmt" ];
        markdown = [
          "prettierd"
          "prettier"
        ];
        javascript = [
          "prettierd"
          "prettier"
        ];
        typescript = [
          "prettierd"
          "prettier"
        ];
        css = [
          "prettierd"
          "prettier"
        ];
        html = [
          "prettierd"
          "prettier"
        ];
        "_" = [ "trim_whitespace" ];
      };
      format_on_save = {
        lsp_fallback = true;
        timeout_ms = 1000;
      };
      notify_on_error = true;
    };
  };

  # ── Lint: async diagnostics ────────────────────────────
  plugins.lint = {
    enable = true;
    lintersByFt = {
      python = [ "pylint" ];
      nix = [ "statix" ];
      sh = [ "shellcheck" ];
      dockerfile = [ "hadolint" ];
      javascript = [ "eslint" ];
      typescript = [ "eslint" ];
    };
  };
}
