{ ... }:
{
  services = {
    # Tailscale daemon is intentionally NOT managed by nix-darwin.
    #
    # The macOS Tailscale app (system extension) owns /var/run/tailscale/
    # tailscaled.sock. Running a second tailscaled via launchd races for
    # that socket, loses, and can corrupt scutil DNS state on its way out.
    #
    # Instead: install only the CLI in environment.systemPackages
    # (hosts/darwin/configuration.nix) so `tailscale` works in the terminal
    # while the app handles the tunnel, tray icon, and DNS injection.
    #
    # tailscale = { enable = true; package = pkgs.tailscale; };

    # ── OmniWM ─────────────────────────────────────────────────────────
    # Niri + Dwindle tiling window manager.
    # Installed via homebrew cask: packages/darwin/homebrew.nix
    # Config is managed by the services.omniwm module from the nix-darwin fork.
    # OmniWM — config managed by home-manager via xdg.configFile
    # with mkOutOfStoreSymlink (a writable symlink back to the repo).
    # The actual settings live in: hosts/darwin/omniwm/settings.toml
    omniwm = {
      enable = true;
    };

    # AeroHUD is not used with OmniWM (OmniWM has its own overview).
    aerohud = {
      enable = false;
    };
  };
}
