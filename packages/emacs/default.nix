# macOS-only store-baked Emacs.app (Mac port — native Cocoa, NOT GTK).
# Expects `pkgs` to already have nix-community/emacs-overlay applied.
{ pkgs, ... }:
let
  inherit (pkgs) lib;

  # ghostel's native (Zig) module fails to build on Darwin inside the Nix
  # sandbox (DarwinSdkNotFound). Swap in the prebuilt release asset instead.
  withPrebuiltGhostelModule = pkgs.callPackage ./ghostel.nix { };

  # emacs-macport = native Cocoa Emacs.app with Mac-specific niceties.
  # This is the "lucid" equivalent on macOS — no GTK, native Cocoa UI.
  emacs = pkgs.emacs-macport;
  emacsPkgs = emacs.pkgs.overrideScope (final: prev: {
    ghostel = withPrebuiltGhostelModule prev.ghostel;
  });

  emacsWithPkgs = emacsPkgs.withPackages (epkgs: [
    epkgs.melpaPackages.evil
    epkgs.melpaPackages.evil-collection
    epkgs.melpaPackages.kanagawa-themes
    epkgs.melpaPackages.nix-mode
    epkgs.melpaPackages.qml-mode
    epkgs.ghostel
    epkgs.melpaStablePackages.evil-ghostel
    epkgs.melpaPackages.vertico
    epkgs.melpaPackages.orderless
    epkgs.melpaPackages.marginalia
    epkgs.melpaPackages.consult
    epkgs.melpaPackages.consult-eglot
    epkgs.melpaPackages.corfu
    epkgs.melpaPackages.cape
    epkgs.melpaPackages.eldoc-box
    epkgs.melpaPackages.markdown-mode
    epkgs.melpaPackages.magit
    epkgs.melpaPackages.neotree
    epkgs.melpaPackages.envrc
    epkgs.melpaPackages.inheritenv
    epkgs.treesit-grammars.with-all-grammars
  ]);

  runtimeTools = [
    pkgs.ripgrep
    pkgs.fd
    pkgs.direnv
    pkgs.rust-analyzer
    pkgs.typescript-language-server
    pkgs.nixd
    pkgs.gopls
    pkgs.elixir-ls
    pkgs.pyright
    pkgs.bash-language-server
    pkgs.vscode-langservers-extracted
    pkgs.dockerfile-language-server
    pkgs.docker-compose-language-service
    pkgs.qt6.qtdeclarative
  ];
  pathSuffix = lib.makeBinPath runtimeTools;
  initDir = ./emacs.d;
in
# macOS: running the raw Emacs binary (what a wrapProgram bin/emacs does) never
# registers as a foreground GUI app — no Dock icon, no keyboard focus. A GUI
# app must be launched as its .app bundle via `open` (Launch Services). So:
#   1. Copy Emacs.app and re-wrap its Mach-O launcher with --init-directory
#      and the runtime-tools PATH baked in;
#   2. Ship `emacs-gui` which `open`s that bundle;
#   3. Keep a normal terminal `emacs` (+ emacsclient) for CLI use.
pkgs.runCommand "emacs-explore" { nativeBuildInputs = [ pkgs.makeBinaryWrapper ]; } ''
  mkdir -p $out/bin $out/Applications

  for entry in ${emacsWithPkgs}/*; do
    base=$(basename "$entry")
    case "$base" in
      bin|Applications) ;;
      *) ln -s "$entry" "$out/$base" ;;
    esac
  done

  for bin in ${emacsWithPkgs}/bin/*; do
    ln -s "$bin" "$out/bin/$(basename "$bin")"
  done
  rm "$out/bin/emacs"
  makeWrapper "${emacsWithPkgs}/bin/emacs" "$out/bin/emacs" \
    --add-flags "--init-directory ${initDir}" \
    --suffix PATH : "${pathSuffix}"
  makeWrapper /usr/bin/open "$out/bin/emacs-gui" \
    --add-flags "-a $out/Applications/Emacs.app"

  cp -R ${emacsWithPkgs}/Applications/Emacs.app "$out/Applications/"
  chmod -R u+w "$out/Applications/Emacs.app"
  wrapProgram "$out/Applications/Emacs.app/Contents/MacOS/Emacs" \
    --add-flags "--init-directory ${initDir}" \
    --suffix PATH : "${pathSuffix}"
''
