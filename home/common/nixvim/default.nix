# home/common/nixvim/default.nix
# ███████╗ █████╗ ████████╗ █████╗ ███╗   ██╗██╗ ██████╗    ██╗   ██╗██╗███╗   ███╗
# ██╔════╝██╔══██╗╚══██╔══╝██╔══██╗████╗  ██║██║██╔════╝    ██║   ██║██║████╗ ████║
# ███████╗███████║   ██║   ███████║██╔██╗ ██║██║██║         ██║   ██║██║██╔████╔██║
# ╚════██║██╔══██║   ██║   ██╔══██║██║╚██╗██║██║██║         ╚██╗ ██╔╝██║██║╚██╔╝██║
# ███████║██║  ██║   ██║   ██║  ██║██║ ╚████║██║╚██████╗     ╚████╔╝ ██║██║ ╚═╝ ██║
# ╚══════╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝ ╚═════╝     ╚═══╝  ╚═╝╚═╝     ╚═╝
#
# Satanic Vim — Cross-platform Neovim configuration via nixvim.
# Imported by every Home Manager config (Linux + macOS).
#
# FreeBSD devil-inspired dark theme with demonic aesthetics.
# Palette: void blacks, devil reds, trident gold, dark magic purples.

{ lib, ... }:
{
  programs.nixvim = {
    enable = true;

    # Allow wezterm.nvim (used by neotest adapter tree)
    nixpkgs.config.allowUnfreePredicate =
      pkg:
      builtins.elem (lib.getName pkg) [
        "wezterm.nvim"
        "jupytext.nvim"
        "vim-jupyter"
      ];

    # ── Import modular configuration ───────────────────────
    # Each module handles a specific concern. Import order
    # doesn't matter since they all set disjoint options.

    # Core: basics, options, leader
    imports = [
      ./themes/satanic.nix

      # Core setup
      ./modules/core.nix
      ./modules/keymaps.nix

      # UI / visual
      ./modules/ui.nix

      # Language / tooling
      ./modules/lang.nix
      ./modules/lsp.nix
      ./modules/completion.nix

      # Navigation
      ./modules/navigation.nix

      # Editing helpers
      ./modules/editing.nix

      # Version control
      ./modules/git.nix

      # Extra tools
      ./modules/tools.nix
    ];

    # ── Extra configuration ────────────────────────────────
    extraConfigLua = ''
      -- Jupyter runtime dir
      local jupyter_runtime = vim.fn.expand("$HOME/.cache/jupyter/runtime")
      vim.fn.mkdir(jupyter_runtime, "p")
      vim.env.JUPYTER_RUNTIME_DIR = jupyter_runtime

      -- Enable clipboard OSC52 for remote terminals (ssh, etc.)
      vim.api.nvim_create_autocmd("VimEnter", {
        callback = function()
          if vim.fn.executable("win32yank.exe") == 1 then
            vim.g.clipboard = {
              name = "win32yank-wsl",
              copy = { ["+"] = "win32yank.exe -i --crlf", ["*"] = "win32yank.exe -i --crlf" },
              paste = { ["+"] = "win32yank.exe -o --lf", ["*"] = "win32yank.exe -o --lf" },
            }
          end
        end,
      })
    '';
  };
}

