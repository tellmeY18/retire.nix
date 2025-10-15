{ pkgs, lib, ... }:
{

  programs.zed-editor = {
    enable = true;
    package = pkgs.zed-editor;

    extraPackages = with pkgs; [
      nixd
      nixpkgs-fmt
      nil
    ];

    userSettings = {
      # UI Configuration
      theme = {
        mode = "dark";
        light = "One Light";
        dark = "Ayu Dark";
      };
      buffer_font_size = 18.0;
      ui_font_size = 16;
      buffer_font_family = "JetBrains Mono";
      base_keymap = "VSCode";
      
      # Editor Behavior
      vim_mode = true;
      tab_size = 2;
      soft_wrap = "editor_width";
      show_whitespaces = "selection";
      
      # Language Models
      language_models = {
        copilot_chat = {
          api_url = "https://api.githubcopilot.com/chat/completions";
          auth_url = "https://api.github.com/copilot_internal/v2/token";
          models_url = "https://api.githubcopilot.com/models";
        };
      };
      
      # Context Servers
      context_servers = {
        nixx = {
          source = "custom";
          command = "nix";
          args = [ "run" "github:natsukium/mcp-servers-nix#mcp-server-fetch" ];
          env = null;
          settings = { };
        };
      };
      
      # Agent Configuration
      agent = {
        default_profile = "write";
        always_allow_tool_actions = true;
        inline_assistant_model = {
          provider = "zed.dev";
          model = "claude-sonnet-4";
        };
        default_model = {
          provider = "copilot_chat";
          model = "claude-sonnet-4";
        };
      };
      
      # Features
      features = {
        edit_prediction_provider = "copilot";
      };
      
      # Telemetry
      telemetry = {
        diagnostics = false;
        metrics = false;
      };
      
      # LSP Configuration
      lsp = {
        nixd = {
          binary = {
            path = "${pkgs.nixd}/bin/nixd";
          };
        };
      };
      
      # File Settings
      file_scan_exclusions = [
        "**/.git"
        "**/.direnv"
        "**/result"
        "**/target"
        "**/node_modules"
      ];
      
      # Terminal
      terminal = {
        shell = {
          program = "${pkgs.zsh}/bin/zsh";
        };
        font_family = "JetBrains Mono";
        font_size = 14;
      };
    };

    userKeymaps = [
      {
        context = "Workspace";
        bindings = {
          "ctrl-shift-t" = "workspace::NewTerminal";
          "ctrl-shift-e" = "workspace::ToggleLeftDock";
        };
      }
      {
        context = "Editor";
        bindings = {
          "ctrl-/" = "editor::ToggleComments";
        };
      }
    ];

    extensions = [
      "nix"
      "catppuccin"
      "tokyo-night"
    ];
  };
}
