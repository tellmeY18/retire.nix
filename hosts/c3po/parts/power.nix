# hosts/c3po/parts/power.nix — power management for c3po.
#
# Shares the server-laptop TLP + lid policy, then adds the bits specific to
# c3po: ignore the DOCKED lid switch too, and disable the sleep targets
# entirely so nothing can suspend a cluster node.
{ ... }:
{
  imports = [ ../../../profiles/server-laptop-power.nix ];

  services.logind.settings.Login.HandleLidSwitchDocked = "ignore";

  # Disable suspend/hibernate entirely
  systemd.targets = {
    sleep.enable = false;
    suspend.enable = false;
    hibernate.enable = false;
    hybrid-sleep.enable = false;
  };
}
