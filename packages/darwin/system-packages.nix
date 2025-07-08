{ pkgs, lib, ... }:
{
  environment.systemPackages = lib.optionals pkgs.stdenv.isDarwin [
    # Editors & Development
    pkgs.vim

    # Media & Graphics
    pkgs.mpv
    pkgs.ffmpeg_6-full
    pkgs.imagemagick
    pkgs.sox
    pkgs.audacity

    # Communication
    pkgs.profanity
    pkgs.gurk-rs

    # Static Site Generation
    pkgs.hugo

    # Infrastructure & DevOps
    pkgs.opentofu
    pkgs.ansible
    pkgs.doctl
    pkgs.supabase-cli
    pkgs.s3cmd
    pkgs.minio-client
    pkgs.podman
    pkgs.podman-tui

    # Runtime & Languages
    pkgs.deno
    pkgs.cargo
    pkgs.rustc
    pkgs.python312Packages.grip
    pkgs.bun
    pkgs.postgresql_16
    pkgs.php
    pkgs.pipenv

    # Network Tools
    pkgs.wget
    pkgs.wireguard-tools
    pkgs.nmap
    pkgs.rsync
    pkgs.ngrok
    pkgs.termshark
    pkgs.testssl

    # System Utilities
    pkgs.ncdu
    pkgs.sops
    pkgs.age
    pkgs.htop
    pkgs.btop
    pkgs.tree
    pkgs.yazi
    pkgs.tealdeer
    pkgs.rclone
    pkgs.neofetch
    pkgs.tmux
    pkgs.bat
    pkgs.comma
    pkgs.glow
    pkgs.qrencode
    pkgs.android-tools
    pkgs.testdisk
    pkgs.mkalias
    pkgs.inetutils
    pkgs.mysql-client
    pkgs.yt-dlp
    pkgs.ripgrep

    # Build Tools
    pkgs.cmake
    pkgs.meson
    pkgs.ninja
    pkgs.gcc14

    # Documentation & Text Processing
    pkgs.pandoc
    pkgs.poppler_utils
    pkgs.ghostscript

    # Applications
    pkgs.thunderbird

    # Development Tools
    pkgs.lazygit
    pkgs.gh
    pkgs.k9s

    # Fun & Games
    pkgs.ytui-music
    pkgs.cmatrix
    pkgs.sssnake
    pkgs.gtypist

    # Data Processing
    pkgs.grex
    pkgs.rPackages.saws
    pkgs.papers
  ];
}
