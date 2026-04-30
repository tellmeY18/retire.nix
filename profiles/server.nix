# profiles/server.nix — defaults for headless / always-on machines
#
# Ensures SSH is available with sane security defaults and that
# the journal is persisted for post-mortem debugging.
#
# Host-specific SSH hardening (PermitRootLogin, X11Forwarding, etc.)
# can override these in hosts/<name>/parts/services.nix.
{ ... }:
{
  # SSH must be available
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PubkeyAuthentication = true;
    };
  };

  # Persistent journal
  services.journald.extraConfig = ''
    Storage=persistent
    SystemMaxUse=500M
  '';
}
