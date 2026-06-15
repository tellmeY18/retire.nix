# modules/completion.nix
# Autocompletion: nvim-cmp, luasnip snippets, Copilot integration.
{ ... }:
{
  # ── nvim-cmp: completion engine ────────────────────────
  plugins.cmp = {
    enable = true;
    settings = {
      completion = {
        completeopt = "menu,menuone,noselect";
      };
      snippet = {
        expand = ''
          function(args)
            require('luasnip').lsp_expand(args.body)
          end
        '';
      };
      sources = [
        {
          name = "nvim_lsp";
          priority = 100;
        }
        {
          name = "luasnip";
          priority = 75;
        }
        {
          name = "copilot";
          priority = 50;
        }
        {
          name = "buffer";
          priority = 25;
        }
        {
          name = "path";
          priority = 20;
        }
      ];
      mapping = {
        "<Tab>" = ''
          cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif require('luasnip').expand_or_jumpable() then
              require('luasnip').expand_or_jump()
            else
              fallback()
            end
          end, { "i", "s" })
        '';
        "<S-Tab>" = ''
          cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif require('luasnip').jumpable(-1) then
              require('luasnip').jump(-1)
            else
              fallback()
            end
          end, { "i", "s" })
        '';
        "<CR>" = "cmp.mapping.confirm({ select = false })";
        "<C-Space>" = "cmp.mapping.complete()";
        "<C-d>" = "cmp.mapping.scroll_docs(-4)";
        "<C-u>" = "cmp.mapping.scroll_docs(4)";
        "<C-e>" = "cmp.mapping.abort()";
      };
      window = {
        completion = {
          border = "rounded";
          winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder,CursorLine:PmenuSel";
        };
        documentation = {
          border = "rounded";
          winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder";
        };
      };
      formatting = {
        fields = [
          "kind"
          "abbr"
          "menu"
        ];
        format = ''
          function(entry, vim_item)
            local icons = {
              Text = "",
              Method = "",
              Function = "",
              Constructor = "",
              Field = "ﰠ",
              Variable = "",
              Class = "ﴯ",
              Interface = "",
              Module = "",
              Property = "ﰠ",
              Unit = "塞",
              Value = "",
              Enum = "",
              Keyword = "",
              Snippet = "",
              Color = "",
              File = "",
              Reference = "",
              Folder = "",
              EnumMember = "",
              Constant = "",
              Struct = "",
              Event = "",
              Operator = "",
              TypeParameter = "",
            }
            vim_item.kind = string.format('%s %s', icons[entry:get_kind()] or "", vim_item.kind)
            vim_item.menu = ({
              nvim_lsp = "[LSP]",
              luasnip = "[Snip]",
              buffer = "[Buf]",
              path = "[Path]",
              copilot = "[Copilot]",
            })[entry.source.name]
            return vim_item
          end
        '';
      };
    };
  };

  # ── LuaSnip: snippet engine ────────────────────────────
  plugins.luasnip = {
    enable = true;
    settings = {
      enable_autosnippets = true;
      store_selection_keys = "<Tab>";
      update_events = "TextChanged,TextChangedI";
    };
    # Use VSCode-style snippets
    fromVscode = [
      { } # loads all from vscode package path
    ];
  };

  # ── Copilot Lua ────────────────────────────────────────
  plugins.copilot-lua = {
    enable = true;
    settings = {
      # Disabled when using copilot-cmp to avoid interference
      suggestion = {
        enabled = false;
      };
      panel = {
        enabled = false;
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

  # ── Copilot cmp source ─────────────────────────────────
  plugins.copilot-cmp = {
    enable = true;
  };

  # ── Copilot Chat ────────────────────────────────────────
  plugins.copilot-chat = {
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

}
