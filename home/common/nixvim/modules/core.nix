# modules/core.nix
# Core Neovim options, globals, and leader key setup.
#
# NOTE: imported via `programs.nixvim.imports`, so options are at
# the nixvim submodule level (no `programs.nixvim` wrapper needed).
{ ... }:
{
  # ── Global leader ──────────────────────────────────────
  globals = {
    mapleader = " ";
    maplocalleader = " ";
  };

  # ── Basic editor options ───────────────────────────────
  opts = {
    # Line numbers
    number = true;
    relativenumber = true;

    # Indentation
    shiftwidth = 2;
    tabstop = 2;
    softtabstop = 2;
    expandtab = true;
    autoindent = true;
    smartindent = true;

    # Wrapping
    wrap = false;
    textwidth = 0;

    # Search
    hlsearch = true;
    incsearch = true;
    ignorecase = true;
    smartcase = true;
    showmatch = true;

    # Cursor & scroll
    cursorline = true;
    scrolloff = 8;
    sidescrolloff = 8;

    # Splits
    splitbelow = true;
    splitright = true;

    # Undo & backup
    undofile = true;
    undolevels = 10000;
    swapfile = false;
    backup = false;
    writebackup = false;

    # Clipboard
    clipboard = "unnamedplus";

    # Performance
    timeoutlen = 500;
    ttimeoutlen = 0;
    updatetime = 300;
    redrawtime = 1500;

    # Folding
    foldmethod = "expr";
    foldexpr = "nvim_treesitter#foldexpr()";
    foldenable = false;
    foldlevel = 99;
    foldcolumn = "0";

    # Mouse
    mouse = "a";
    mousemodel = "extend";

    # Appearance
    termguicolors = true;
    signcolumn = "yes";
    colorcolumn = "88";
  };

  # ── General filetype behavior ──────────────────────────
  filetype = {
    extension = {
      mdx = "markdown";
    };
  };

  # ── Web devicons (required by many plugins) ────────────
  plugins.web-devicons = {
    enable = true;
    settings = {
      color_icons = true;
      default = true;
      strict = true;
    };
  };
}
