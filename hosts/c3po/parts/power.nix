# hosts/c3po/parts/power.nix — Keep running with lid closed (server laptop)
#
# c3po is a laptop repurposed as a server. It must not suspend or
# hibernate when the lid is closed.
{ ... }:
{
  # Ignore lid close — keep running as a headless server
  services.logind.settings.Login = {
    HandleLidSwitch = "ignore";
    HandleLidSwitchExternalPower = "ignore";
    HandleLidSwitchDocked = "ignore";
  };

  # Disable suspend/hibernate entirely
  systemd.targets = {
    sleep.enable = false;
    suspend.enable = false;
    hibernate.enable = false;
    hybrid-sleep.enable = false;
  };
}
