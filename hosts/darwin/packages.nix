{ pkgs, ... }:

{
  # System packages
  environment.systemPackages = with pkgs; lib.optionals stdenv.isDarwin [
    # Editors & Development
    vim

    # Media & Graphics
    mpv
    ffmpeg_6-full
    imagemagick
    sox
    audacity

    # Communication
    profanity
    gurk-rs

    # Static Site Generation
    hugo

    # Infrastructure & DevOps
    opentofu
    ansible
    doctl
    supabase-cli
    s3cmd
    minio-client
    podman
    podman-tui

    # Runtime & Languages
    deno
    cargo
    rustc
    python312Packages.grip
    bun
    postgresql_16
    php
    pipenv

    # Network Tools
    wget
    wireguard-tools
    nmap
    rsync
    ngrok
    termshark
    testssl

    # System Utilities
    ncdu
    sops
    age
    htop
    btop
    tree
    yazi
    tealdeer
    rclone
    neofetch
    tmux
    bat
    comma
    glow
    qrencode
    android-tools
    testdisk
    mkalias
    inetutils
    mysql-client
    yt-dlp
    ripgrep

    # Build Tools
    cmake
    meson
    ninja
    gcc14

    # Documentation & Text Processing
    pandoc
    poppler_utils
    ghostscript

    # Applications
    thunderbird

    # Development Tools
    lazygit
    gh
    k9s

    # Fun & Games
    ytui-music
    cmatrix
    sssnake
    gtypist

    # Data Processing
    grex
    rPackages.saws
    papers
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];
}
