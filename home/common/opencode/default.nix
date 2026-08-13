{
  pkgs,
  lib,
  config,
  self,
  ...
}:

let
  inherit (lib) mkIf;
in
{
  programs.opencode = {
    enable = true;

    extraPackages = with pkgs; [
      nodejs
      uv
      nix-output-monitor
    ];

    settings = {
      model = "zen/deepseek-v4-flash";
      autoshare = false;
      autoupdate = true;
      default_agent = "auto";
      provider = {
        greenpt = {
          npm = "@ai-sdk/openai-compatible";
          name = "GreenPT";
          options = {
            baseURL = "https://api.greenpt.ai/v1";
            apiKey = "{env:GREEN_KEY}";
          };
          models = {
            # ── Coding-first models ──
            "kimi-k3" = { name = "Kimi K3"; };
            "kimi-k2.7-code" = { name = "Kimi K2.7 Code"; };
            "kimi-k2.6" = { name = "Kimi K2.6"; };
            "devstral-2-123b-instruct-2512" = { name = "Devstral 2 123B"; };
            "devstral-small-2505" = { name = "Devstral Small 24B"; };
            "qwen3-coder-30b-a3b-instruct" = { name = "Qwen3 Coder 30B"; };
            "deepseek-v4-flash-0731" = { name = "DeepSeek V4 Flash"; };
            "gpt-oss-120b" = { name = "GPT-OSS 120B"; };

            # ── General frontier models ──
            "qwen3.5-397b-a17b" = { name = "Qwen 3.5 397B"; };
            "qwen3.6-35b-a3b" = { name = "Qwen 3.6 35B"; };
            "qwen3-235b-a22b-instruct-2507" = { name = "Qwen3 235B"; };
            "glm-5.2" = { name = "GLM 5.2"; };
            "glm-5.2-ponytail" = { name = "GLM 5.2 Ponytail"; };
            "glm-5.2-ponytail-ultra" = { name = "GLM 5.2 Ponytail Ultra"; };
            "glm-5.2-ponytail-lite" = { name = "GLM 5.2 Ponytail Lite"; };
            "glm-5.2-honey" = { name = "GLM 5.2 Honey"; };
            "glm-5.2-honey-ultra" = { name = "GLM 5.2 Honey Ultra"; };
            "glm-5.2-honey-lite" = { name = "GLM 5.2 Honey Lite"; };
            "glm-5.2-caveman" = { name = "GLM 5.2 Caveman"; };
            "glm-5.2-caveman-ultra" = { name = "GLM 5.2 Caveman Ultra"; };
            "glm-5.2-caveman-lite" = { name = "GLM 5.2 Caveman Lite"; };
            "minimax-m2.5" = { name = "MiniMax M2.5"; };
            "gemma4" = { name = "Gemma 4"; };
            "gemma-3-27b-it" = { name = "Gemma 3 27B"; };
            "holo2-30b-a3b" = { name = "Holo2 30B"; };

            # ── Mistral family ──
            "mistral-medium-3.5-128b" = { name = "Mistral Medium 3.5 128B"; };
            "mistral-small-3.2-24b-instruct-2506" = { name = "Mistral Small 3.2 24B"; };
            "mistral-nemo-instruct-2407" = { name = "Mistral Nemo 12B"; };
            "voxtral-small-24b-2507" = { name = "Voxtral Small 24B"; };
            "pixtral-12b-2409" = { name = "Pixtral 12B"; };

            # ── Meta Llama ──
            "llama-3.3-70b-instruct" = { name = "Llama 3.3 70B"; };
            "llama-3.1-8b-instruct" = { name = "Llama 3.1 8B"; };
            "deepseek-r1-distill-llama-70b" = { name = "DeepSeek R1 Distill 70B"; };

            # ── GreenPT native ──
            "green-l" = { name = "Green L"; };
            "green-l-raw" = { name = "Green L Raw"; };
            "green-r" = { name = "Green R"; };
            "green-r-raw" = { name = "Green R Raw"; };
            "green-s" = { name = "Green S"; };
            "green-s-pro" = { name = "Green S Pro"; };
          };
        };
      };
    };

    tui = {
      theme = "nord";
      keybinds = {
        leader = "alt+b";
      };
      scroll = {
        jump_size = 5;
      };
    };

    # Move wiki.fosscell.org MCP config from repo-level opencode.json to
    # user-level config so the hardcoded path is managed declaratively.
    enableMcpIntegration = true;
  };

  programs.mcp = {
    enable = true;
    servers = {
      "wiki.fosscell.org" = {
        command = "npx";
        args = [
          "-y"
          "@professional-wiki/mediawiki-mcp-server"
        ];
        env = {
          CONFIG = "${config.home.homeDirectory}/.config/mediawiki-mcp/config.json";
        };
      };
    };
  };

  # Nord theme for opencode TUI
  programs.opencode.themes = {
    nord = {
      defs = {
        nord0 = "#2E3440";
        nord1 = "#3B4252";
        nord2 = "#434C5E";
        nord3 = "#4C566A";
        nord4 = "#D8DEE9";
        nord5 = "#E5E9F0";
        nord6 = "#ECEFF4";
        nord7 = "#8FBCBB";
        nord8 = "#88C0D0";
        nord9 = "#81A1C1";
        nord10 = "#5E81AC";
        nord11 = "#BF616A";
        nord12 = "#D08770";
        nord13 = "#EBCB8B";
        nord14 = "#A3BE8C";
        nord15 = "#B48EAD";
      };
      theme = {
        accent = {
          dark = "nord7";
          light = "nord7";
        };
        background = {
          dark = "nord0";
          light = "nord6";
        };
        backgroundElement = {
          dark = "nord1";
          light = "nord4";
        };
        backgroundPanel = {
          dark = "nord1";
          light = "nord5";
        };
        border = {
          dark = "nord2";
          light = "nord3";
        };
        borderActive = {
          dark = "nord3";
          light = "nord2";
        };
        borderSubtle = {
          dark = "nord2";
          light = "nord3";
        };
        diffAdded = {
          dark = "nord14";
          light = "nord14";
        };
        diffAddedBg = {
          dark = "#3B4252";
          light = "#E5E9F0";
        };
        diffAddedLineNumberBg = {
          dark = "#3B4252";
          light = "#E5E9F0";
        };
        diffContext = {
          dark = "nord3";
          light = "nord3";
        };
        diffContextBg = {
          dark = "nord1";
          light = "nord5";
        };
        diffHighlightAdded = {
          dark = "nord14";
          light = "nord14";
        };
        diffHighlightRemoved = {
          dark = "nord11";
          light = "nord11";
        };
        diffHunkHeader = {
          dark = "nord3";
          light = "nord3";
        };
        diffLineNumber = {
          dark = "nord2";
          light = "nord4";
        };
        diffRemoved = {
          dark = "nord11";
          light = "nord11";
        };
        diffRemovedBg = {
          dark = "#3B4252";
          light = "#E5E9F0";
        };
        diffRemovedLineNumberBg = {
          dark = "#3B4252";
          light = "#E5E9F0";
        };
        error = {
          dark = "nord11";
          light = "nord11";
        };
        info = {
          dark = "nord8";
          light = "nord10";
        };
        markdownBlockQuote = {
          dark = "nord3";
          light = "nord3";
        };
        markdownCode = {
          dark = "nord14";
          light = "nord14";
        };
        markdownCodeBlock = {
          dark = "nord4";
          light = "nord0";
        };
        markdownEmph = {
          dark = "nord12";
          light = "nord12";
        };
        markdownHeading = {
          dark = "nord8";
          light = "nord10";
        };
        markdownHorizontalRule = {
          dark = "nord3";
          light = "nord3";
        };
        markdownImage = {
          dark = "nord9";
          light = "nord9";
        };
        markdownImageText = {
          dark = "nord7";
          light = "nord7";
        };
        markdownLink = {
          dark = "nord9";
          light = "nord9";
        };
        markdownLinkText = {
          dark = "nord7";
          light = "nord7";
        };
        markdownListEnumeration = {
          dark = "nord7";
          light = "nord7";
        };
        markdownListItem = {
          dark = "nord8";
          light = "nord10";
        };
        markdownStrong = {
          dark = "nord13";
          light = "nord13";
        };
        markdownText = {
          dark = "nord4";
          light = "nord0";
        };
        primary = {
          dark = "nord8";
          light = "nord10";
        };
        secondary = {
          dark = "nord9";
          light = "nord9";
        };
        success = {
          dark = "nord14";
          light = "nord14";
        };
        syntaxComment = {
          dark = "nord3";
          light = "nord3";
        };
        syntaxFunction = {
          dark = "nord8";
          light = "nord8";
        };
        syntaxKeyword = {
          dark = "nord9";
          light = "nord9";
        };
        syntaxNumber = {
          dark = "nord15";
          light = "nord15";
        };
        syntaxOperator = {
          dark = "nord9";
          light = "nord9";
        };
        syntaxPunctuation = {
          dark = "nord4";
          light = "nord0";
        };
        syntaxString = {
          dark = "nord14";
          light = "nord14";
        };
        syntaxType = {
          dark = "nord7";
          light = "nord7";
        };
        syntaxVariable = {
          dark = "nord7";
          light = "nord7";
        };
        text = {
          dark = "nord4";
          light = "nord0";
        };
        textMuted = {
          dark = "nord3";
          light = "nord1";
        };
        warning = {
          dark = "nord12";
          light = "nord12";
        };
      };
    };
  };

  # Global context — instructions every opencode session gets
  programs.opencode.context = ''
    # Nix Flake Configuration

    This repository manages a unified Nix flake for macOS (nix-darwin) and
    NixOS systems. Follow these guidelines:

    ## Shell & Build Commands
    - Use `nh` (never nixos-rebuild/darwin-rebuild) — see the nix-rebuild skill.
    - For k3s cluster nodes, use `deploy-rs` via `just deploy <host>`.
    - `just` is the canonical task runner — run `just` to list available commands.

    ## Code Standards
    - Run `treefmt` before committing (nix + shell + markdown formatting).
    - Format Nix files with nixpkgs-fmt.
    - Keep modules focused: one file = one concern.
    - New hosts: `mkdir hosts/<name>`, add metadata.nix + configuration.nix.

    ## Key Files
    - `flake.nix` — entry point and output definitions
    - `CLAUDE.md` — full audit and improvement checklist
    - `ROADMAP.md` — milestone plan
    - `Justfile` — task definitions for builds, deploys, and day-2 ops
    - `lib/default.nix` — host factories and auto-discovery helpers
  '';

  # Custom agents for common workflows
  programs.opencode.agents = {
    nix-expert = ''
      # Nix Expert Agent

      You are a Nix/NixOS expert with deep knowledge of:
      - Nix language (functional, lazy, pure)
      - Flakes, NixOS modules, Home Manager modules
      - nix-darwin for macOS configuration
      - Nixpkgs packaging conventions
      - nixpkgs-fmt, statix, deadnix tooling

      ## Guidelines
      - Prefer `lib.mkIf` and `lib.optionalAttrs` over duplicate config blocks
      - Use `lib.mkForce` sparingly and always with a comment explaining why
      - Factor shared logic into `lib/` helpers
      - Keep flake.nix minimal — use auto-discovery in `lib/default.nix`
      - Prefer attribute paths over `with` expressions
    '';

    k8s-ops = ''
      # Kubernetes Operations Agent

      You manage a 3-node k3s cluster (chopper, c3po, kenobi) with embedded
      etcd, running production PostgreSQL (CNPG) and MySQL Group Replication.

      ## Cluster topology
      - chopper: k3s server-init (etcd + apiserver + storage)
      - c3po: k3s server (etcd + storage)
      - kenobi: k3s server (compute node, OCI ARM VM)

      ## Key resources
      - HA endpoint: https://k3s-cp.tail477f2f.ts.net:6443
      - All manifests in k8s/ directory
      - Helmfile for chart management
      - deploy-rs for NixOS node configs (NEVER deploy 2 nodes at once)

      ## References
      - See deploy-k3s-nodes skill for deployment safety procedures
      - See k8s/README.md for cluster operations
    '';
  };

  # Custom commands for quick workflows
  programs.opencode.commands = {
    build = ''
      # Build Command

      Build a Nix configuration for this repository.
      Usage: /build [target]

      Targets:
      - mac       Build darwin config (default)
      - chopper   Build chopper NixOS
      - c3po      Build c3po NixOS
      - kenobi    Build kenobi NixOS
      - home      Build HM config for Mac
      - all       Build everything
    '';

    deploy = ''
      # Deploy Command

      Deploy NixOS config to a remote host via deploy-rs.
      Usage: /deploy <host>

      Hosts: chopper, c3po, kenobi

      IMPORTANT: Never deploy two etcd nodes at once.
    '';
  };

  # Reference existing skill directories from the flake source tree.
  # `self` is the flake output, passed via _module.args in flake.nix.
  programs.opencode.skills = {
    deploy-k3s-nodes = "${self.outPath}/.agents/skills/deploy-k3s-nodes";
    nix-rebuild = "${self.outPath}/.agents/skills/nix-rebuild";
  };
}
