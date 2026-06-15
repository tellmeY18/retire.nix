# modules/keymaps.nix
# All keybindings organized by category with which-key descriptions.
{ ... }:
{
  # ── Keymap options ─────────────────────────────────────
  keymaps = [
    # ── Better escape ────────────────────────────────────
    {
      mode = "i";
      key = "jk";
      action = "<Esc>";
      options = {
        desc = "Exit insert mode";
      };
    }
    {
      mode = "i";
      key = "kj";
      action = "<Esc>";
      options = {
        desc = "Exit insert mode";
      };
    }

    # ── Window management ────────────────────────────────
    {
      key = "<C-h>";
      action = "<C-w>h";
      options = {
        desc = "Focus left window";
      };
    }
    {
      key = "<C-j>";
      action = "<C-w>j";
      options = {
        desc = "Focus down window";
      };
    }
    {
      key = "<C-k>";
      action = "<C-w>k";
      options = {
        desc = "Focus up window";
      };
    }
    {
      key = "<C-l>";
      action = "<C-w>l";
      options = {
        desc = "Focus right window";
      };
    }

    # ── Tab management ──────────────────────────────────
    {
      key = "<S-l>";
      action = "<cmd>tabnext<CR>";
      options = {
        desc = "Next tab";
      };
    }
    {
      key = "<S-h>";
      action = "<cmd>tabprev<CR>";
      options = {
        desc = "Previous tab";
      };
    }
    {
      key = "<leader>tn";
      action = "<cmd>tabnew<CR>";
      options = {
        desc = "New tab";
      };
    }
    {
      key = "<leader>tc";
      action = "<cmd>tabclose<CR>";
      options = {
        desc = "Close tab";
      };
    }
    {
      key = "<leader>to";
      action = "<cmd>tabonly<CR>";
      options = {
        desc = "Close other tabs";
      };
    }

    # ── Split management ─────────────────────────────────
    {
      key = "<leader>sv";
      action = "<C-w>v";
      options = {
        desc = "Split vertically";
      };
    }
    {
      key = "<leader>sh";
      action = "<C-w>s";
      options = {
        desc = "Split horizontally";
      };
    }
    {
      key = "<leader>se";
      action = "<C-w>=";
      options = {
        desc = "Equalize splits";
      };
    }
    {
      key = "<leader>sx";
      action = "<cmd>close<CR>";
      options = {
        desc = "Close current split";
      };
    }

    # ── Buffer management ────────────────────────────────
    {
      key = "<leader>bd";
      action = "<cmd>bdelete<CR>";
      options = {
        desc = "Delete buffer";
      };
    }
    {
      key = "<leader>bD";
      action = "<cmd>bufdo bdelete<CR>";
      options = {
        desc = "Delete all buffers";
      };
    }
    {
      key = "<leader>bl";
      action = "<cmd>buffer<CR>";
      options = {
        desc = "List buffers";
      };
    }
    {
      key = "<leader>bP";
      action = "<cmd>Telescope buffers<CR>";
      options = {
        desc = "Pick buffer";
      };
    }

    # ── Quick navigation ─────────────────────────────────
    {
      key = "<leader>w";
      action = "<C-w>";
      options = {
        desc = "Window commands";
      };
    }
    {
      key = "<leader><Tab>";
      action = "<C-^>";
      options = {
        desc = "Switch to alternate buffer";
      };
    }

    # ── Search / find ─────────────────────────────────────
    {
      key = "<leader>ff";
      action = "<cmd>Telescope find_files<CR>";
      options = {
        desc = "Find files";
      };
    }
    {
      key = "<leader>fg";
      action = "<cmd>Telescope live_grep<CR>";
      options = {
        desc = "Live grep";
      };
    }
    {
      key = "<leader>fb";
      action = "<cmd>Telescope buffers<CR>";
      options = {
        desc = "Find buffers";
      };
    }
    {
      key = "<leader>fh";
      action = "<cmd>Telescope help_tags<CR>";
      options = {
        desc = "Help tags";
      };
    }
    {
      key = "<leader>fo";
      action = "<cmd>Telescope oldfiles<CR>";
      options = {
        desc = "Recent files";
      };
    }
    {
      key = "<leader>fk";
      action = "<cmd>Telescope keymaps<CR>";
      options = {
        desc = "Find keymaps";
      };
    }
    {
      key = "<leader>fc";
      action = "<cmd>Telescope commands<CR>";
      options = {
        desc = "Commands";
      };
    }
    {
      key = "<leader>fC";
      action = "<cmd>Telescope colorscheme<CR>";
      options = {
        desc = "Colorschemes";
      };
    }
    {
      key = "<leader>fr";
      action = "<cmd>Telescope resume<CR>";
      options = {
        desc = "Resume last search";
      };
    }

    # ── Git keymaps ──────────────────────────────────────
    {
      key = "<leader>gg";
      action = "<cmd>Neogit<CR>";
      options = {
        desc = "Neogit";
      };
    }
    {
      key = "<leader>gd";
      action = "<cmd>DiffviewOpen<CR>";
      options = {
        desc = "Diffview";
      };
    }
    {
      key = "<leader>gD";
      action = "<cmd>DiffviewClose<CR>";
      options = {
        desc = "Diffview close";
      };
    }
    {
      key = "<leader>gf";
      action = "<cmd>DiffviewFileHistory<CR>";
      options = {
        desc = "File history";
      };
    }

    # ── Navigation (Harpoon, Trouble) ────────────────────
    {
      key = "<leader>ha";
      action = "<cmd>lua require('harpoon.mark').add_file()<CR>";
      options = {
        desc = "Harpoon mark file";
      };
    }
    {
      key = "<leader>hh";
      action = "<cmd>lua require('harpoon.ui').toggle_quick_menu()<CR>";
      options = {
        desc = "Harpoon quick menu";
      };
    }
    {
      key = "<leader>h1";
      action = "<cmd>lua require('harpoon.ui').nav_file(1)<CR>";
      options = {
        desc = "Harpoon mark 1";
      };
    }
    {
      key = "<leader>h2";
      action = "<cmd>lua require('harpoon.ui').nav_file(2)<CR>";
      options = {
        desc = "Harpoon mark 2";
      };
    }
    {
      key = "<leader>h3";
      action = "<cmd>lua require('harpoon.ui').nav_file(3)<CR>";
      options = {
        desc = "Harpoon mark 3";
      };
    }
    {
      key = "<leader>h4";
      action = "<cmd>lua require('harpoon.ui').nav_file(4)<CR>";
      options = {
        desc = "Harpoon mark 4";
      };
    }

    # ── Trouble ──────────────────────────────────────────
    {
      key = "<leader>xx";
      action = "<cmd>Trouble diagnostics toggle<CR>";
      options = {
        desc = "Trouble (diagnostics)";
      };
    }
    {
      key = "<leader>xw";
      action = "<cmd>Trouble workspace_diagnostics toggle<CR>";
      options = {
        desc = "Workspace diagnostics";
      };
    }
    {
      key = "<leader>xd";
      action = "<cmd>Trouble document_diagnostics toggle<CR>";
      options = {
        desc = "Document diagnostics";
      };
    }
    {
      key = "<leader>xl";
      action = "<cmd>Trouble loclist toggle<CR>";
      options = {
        desc = "Location list";
      };
    }
    {
      key = "<leader>xq";
      action = "<cmd>Trouble quickfix toggle<CR>";
      options = {
        desc = "Quickfix list";
      };
    }
    {
      key = "<leader>xr";
      action = "<cmd>Trouble lsp_references toggle<CR>";
      options = {
        desc = "LSP references";
      };
    }

    # ── Terminal ─────────────────────────────────────────
    {
      mode = [
        "n"
        "t"
      ];
      key = "<leader>tt";
      action = "<cmd>ToggleTerm<CR>";
      options = {
        desc = "Toggle terminal";
      };
    }
    {
      mode = [
        "n"
        "t"
      ];
      key = "<leader>tf";
      action = "<cmd>ToggleTerm direction=float<CR>";
      options = {
        desc = "Floating terminal";
      };
    }
    {
      mode = [
        "n"
        "t"
      ];
      key = "<leader>tv";
      action = "<cmd>ToggleTerm direction=vertical size=80<CR>";
      options = {
        desc = "Vertical terminal";
      };
    }
    {
      mode = [
        "n"
        "t"
      ];
      key = "<leader>th";
      action = "<cmd>ToggleTerm direction=horizontal<CR>";
      options = {
        desc = "Horizontal terminal";
      };
    }
    {
      mode = "t";
      key = "<Esc>";
      action = "<C-\\><C-n>";
      options = {
        desc = "Exit terminal mode";
      };
    }
    {
      mode = "t";
      key = "<C-'>";
      action = "<cmd>ToggleTerm<CR>";
      options = {
        desc = "ToggleTerm from terminal";
      };
    }

    # ── Tools ────────────────────────────────────────────
    {
      key = "<leader>uu";
      action = "<cmd>UndotreeToggle<CR>";
      options = {
        desc = "Undo tree";
      };
    }
    {
      key = "<leader>uz";
      action = "<cmd>UndotreeFocus<CR>";
      options = {
        desc = "Undo tree focus";
      };
    }

    # ── Neotest (disabled — add back when adapters configured) ──

    # ── General escape / convenience ────────────────────
    {
      key = "<leader>n";
      action = "<cmd>nohlsearch<CR>";
      options = {
        desc = "Clear search highlights";
      };
    }

    # ── Quickfix / location list ─────────────────────────
    {
      key = "<leader>cn";
      action = "<cmd>cnext<CR>";
      options = {
        desc = "Next quickfix item";
      };
    }
    {
      key = "<leader>cp";
      action = "<cmd>cprev<CR>";
      options = {
        desc = "Previous quickfix item";
      };
    }
    {
      key = "<leader>ln";
      action = "<cmd>lnext<CR>";
      options = {
        desc = "Next location item";
      };
    }
    {
      key = "<leader>lp";
      action = "<cmd>lprev<CR>";
      options = {
        desc = "Previous location item";
      };
    }

    # ── Motion / scroll ──────────────────────────────────
    {
      key = "<C-d>";
      action = "<C-d>zz";
      options = {
        desc = "Scroll down half-page (center)";
      };
    }
    {
      key = "<C-u>";
      action = "<C-u>zz";
      options = {
        desc = "Scroll up half-page (center)";
      };
    }
    {
      key = "n";
      action = "nzzzv";
      options = {
        desc = "Next search result (center)";
      };
    }
    {
      key = "N";
      action = "Nzzzv";
      options = {
        desc = "Prev search result (center)";
      };
    }

    # ── Flash navigation (from Jump mode) ────────────────
    {
      mode = [
        "n"
        "x"
        "o"
      ];
      key = "s";
      action = "<cmd>lua require('flash').jump()<CR>";
      options = {
        desc = "Flash jump";
      };
    }
    {
      mode = [
        "n"
        "x"
        "o"
      ];
      key = "S";
      action = "<cmd>lua require('flash').treesitter()<CR>";
      options = {
        desc = "Flash treesitter";
      };
    }
    {
      mode = "o";
      key = "r";
      action = "<cmd>lua require('flash').remote()<CR>";
      options = {
        desc = "Flash remote";
      };
    }
    {
      mode = [
        "o"
        "x"
      ];
      key = "R";
      action = "<cmd>lua require('flash').treesitter_search()<CR>";
      options = {
        desc = "Flash treesitter search";
      };
    }

    # ── NvimTree ─────────────────────────────────────────
    {
      key = "<leader>e";
      action = "<cmd>NvimTreeToggle<CR>";
      options = {
        desc = "Toggle file tree";
      };
    }
    {
      key = "<leader>E";
      action = "<cmd>NvimTreeFocus<CR>";
      options = {
        desc = "Focus file tree";
      };
    }

    # ── Vim-maximizer ────────────────────────────────────
    {
      key = "<leader>sm";
      action = "<cmd>MaximizerToggle<CR>";
      options = {
        desc = "Maximize / restore split";
      };
    }

    # ── Visual mode: paste without losing selection ──────
    {
      mode = "v";
      key = "p";
      action = "pgvy";
      options = {
        desc = "Paste without losing selection";
      };
    }

    # ── Move lines in visual mode ────────────────────────
    {
      mode = "v";
      key = "<A-j>";
      action = ":m '>+1<CR>gv=gv";
      options = {
        desc = "Move line down";
      };
    }
    {
      mode = "v";
      key = "<A-k>";
      action = ":m '<-2<CR>gv=gv";
      options = {
        desc = "Move line up";
      };
    }

    # ── Molten (Jupyter) ─────────────────────────────────
    {
      mode = "n";
      key = "<leader>mi";
      action = "<cmd>MoltenInit<CR>";
      options = {
        desc = "Molten init";
      };
    }
    {
      mode = [
        "n"
        "v"
      ];
      key = "<leader>me";
      action = "<cmd>MoltenEvaluateOperator<CR>";
      options = {
        desc = "Molten evaluate";
      };
    }
    {
      mode = "n";
      key = "<leader>mr";
      action = "<cmd>MoltenReevaluateCell<CR>";
      options = {
        desc = "Molten reevaluate";
      };
    }
    {
      mode = "n";
      key = "<leader>mR";
      action = "<cmd>MoltenEvaluateFile<CR>";
      options = {
        desc = "Molten evaluate file";
      };
    }
    {
      mode = "n";
      key = "<leader>mo";
      action = "<cmd>MoltenOpenOutputSplit<CR>";
      options = {
        desc = "Molten open output";
      };
    }
    {
      mode = "n";
      key = "<leader>mh";
      action = "<cmd>MoltenHideOutput<CR>";
      options = {
        desc = "Molten hide output";
      };
    }
    {
      mode = "n";
      key = "<leader>md";
      action = "<cmd>MoltenDelete<CR>";
      options = {
        desc = "Molten delete cell";
      };
    }

    # ── Vimtex ───────────────────────────────────────────
    {
      mode = "n";
      key = "<leader>lv";
      action = "<cmd>VimtexView<CR>";
      options = {
        desc = "Vimtex view";
      };
    }
    {
      mode = "n";
      key = "<leader>lt";
      action = "<cmd>VimtexTocOpen<CR>";
      options = {
        desc = "Vimtex TOC";
      };
    }
    {
      mode = "n";
      key = "<leader>lc";
      action = "<cmd>VimtexClean<CR>";
      options = {
        desc = "Vimtex clean";
      };
    }

    # ── Markdown preview ─────────────────────────────────
    {
      mode = "n";
      key = "<leader>mp";
      action = "<cmd>MarkdownPreviewToggle<CR>";
      options = {
        desc = "Toggle markdown preview";
      };
    }

    # ── Delete to void register ──────────────────────────
    {
      mode = "v";
      key = "<leader>d";
      action = "\"_d";
      options = {
        desc = "Delete to void register (visual)";
      };
    }
  ];
}
