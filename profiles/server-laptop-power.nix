# profiles/server-laptop-power.nix — TLP + lid policy for laptops that are
# actually servers (chopper, c3po).
#
# Keeps the machine at full performance on AC, caps battery charge to prolong
# lifespan, and ignores the lid so closing it doesn't take a cluster node down.
#
# Hosts layer their own extras on top — c3po additionally ignores the docked
# lid switch and disables the sleep/suspend targets outright.
#
# NOT profiles/laptop.nix: that one also enables NetworkManager and installs
# powertop, which these server-laptops don't want.
{ ... }:
{
  services = {
    tlp = {
      enable = true;
      # See https://linrunner.de/tlp/settings/ for all available options.
      # These are some common settings for fine-tuning power management on laptops.
      settings = {
        # Set the default mode and enable TLP.
        TLP_DEFAULT_MODE = "AC";
        TLP_ENABLE = 1;

        # --- CPU Tuning ---
        # Use 'performance' governor on AC for responsiveness,
        # and 'powersave' on battery for longevity.
        CPU_SCALING_GOVERNOR_ON_AC = "performance";
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

        # Allow CPU to reach max performance on AC.
        # Prevent CPU from using "turbo boost" on battery to save power.
        CPU_BOOST_ON_AC = 0;
        CPU_BOOST_ON_BAT = 0;

        # Set energy performance hints.
        CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
        CPU_ENERGY_PERF_POLICY_ON_BAT = "power";

        # --- Disk / Filesystem ---
        # Minimize disk power saving on AC for faster access.
        # Use medium power saving on battery.
        DISK_APM_LEVEL_ON_AC = "254";
        DISK_APM_LEVEL_ON_BAT = "128";

        # SATA link power management. 'max_performance' on AC, 'min_power' on battery.
        SATA_LINKPWR_ON_AC = "max_performance";
        SATA_LINKPWR_ON_BAT = "min_power";

        # --- PCIe ---
        # Active State Power Management for PCIe devices.
        PCIE_ASPM_ON_AC = "performance";
        PCIE_ASPM_ON_BAT = "powersave";

        # --- Audio ---
        # Disable audio power saving on AC to prevent clicks.
        # Enable on battery.
        SOUND_POWER_SAVE_ON_AC = 1;
        SOUND_POWER_SAVE_ON_BAT = 1;
        SOUND_POWER_SAVE_CONTROLLER = "Y";

        # --- Battery Care ---
        # For ThinkPads and other supported models to prolong battery lifespan.
        START_CHARGE_THRESH_BAT0 = 45;
        STOP_CHARGE_THRESH_BAT0 = 80;
      };
    };

    logind.settings = {
      Login = {
        HandleLidSwitch = "ignore";
        HandleLidSwitchExternalPower = "ignore";
      };
    };
  };
}
