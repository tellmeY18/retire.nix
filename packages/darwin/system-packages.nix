{ pkgs, lib, ... }:
{
  environment.systemPackages = lib.optionals pkgs.stdenv.isDarwin [
    # Editors & Development
    pkgs.emacs-macport

    # Media & Graphics
    pkgs.imagemagick
    pkgs.sox

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
    pkgs.nh
    pkgs.podman
    pkgs.podman-compose
    pkgs.kubectl
    pkgs.podman-tui
    pkgs.just

    # Runtime & Languages
    pkgs.python312Packages.grip
    pkgs.bun
    pkgs.postgresql_16
    pkgs.php
    pkgs.pipenv
    pkgs.nixd

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
    pkgs.btop
    pkgs.yazi
    pkgs.tealdeer
    pkgs.rclone
    pkgs.comma
    pkgs.glow
    pkgs.qrencode
    pkgs.android-tools
    pkgs.testdisk
    pkgs.mkalias
    pkgs.inetutils
    pkgs.yt-dlp

    # Build Tools
    pkgs.cmake
    pkgs.meson
    pkgs.ninja
    pkgs.gcc14
    pkgs.zig

    # Documentation & Text Processing
    pkgs.pandoc
    pkgs.poppler-utils
    pkgs.ghostscript

    # Development Tools
    pkgs.lazygit
    pkgs.gh
    pkgs.k9s
    pkgs.entire

    # Fun & Games
    pkgs.cmatrix
    pkgs.sssnake
    pkgs.gtypist

    # Data Processing
    pkgs.grex
    pkgs.super-productivity
    pkgs.rPackages.saws
    pkgs.sshuttle
  ];
}
