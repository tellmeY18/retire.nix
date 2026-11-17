# hosts/chopper/parts/fingerprint.nix — ELAN7001 SPI fingerprint reader.
#
# The sensor (ACPI ELAN7001, Intel LPSS SPI) has no kernel driver; libfprint's
# elanspi driver talks to it through spidev and resets it via the touchpad's
# hidraw node. Upstream's match table lacks this laptop's touchpad (04F3:30EF).
{ pkgs, ... }:
let
  libfprint = pkgs.libfprint.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      substituteInPlace libfprint/drivers/elanspi.h --replace-fail \
        '  {.udev_types = 0}' \
        '  {.udev_types = ELANSPI_UDEV_TYPES, .spi_acpi_id = "ELAN7001", .hid_id = {.vid = ELANSPI_TP_VID, .pid = 0x30ef}, .driver_data = ELANSPI_90LEFT_ROTATE},
        {.udev_types = 0}'

      # The sensor polls while waiting for a finger; the default thermal model
      # (3 min hot) locks it out mid-enrollment. Other drivers opt out too.
      substituteInPlace libfprint/drivers/elanspi.c --replace-fail \
        'dev_class->scan_type = FP_SCAN_TYPE_SWIPE;' \
        'dev_class->scan_type = FP_SCAN_TYPE_SWIPE;
        dev_class->temp_hot_seconds = -1;'
    '';
  });
in
{
  services.fprintd = {
    enable = true;
    package = pkgs.fprintd.override { inherit libfprint; };
  };

  # Keep the agent's graphical `sudo -A` path free of fingerprint prompts.
  security.pam.services.sudo.fprintAuth = false;

  # No in-tree driver claims the sensor, so hand it to spidev at boot.
  boot.kernelModules = [ "spidev" ];
  systemd.services.elan-spi-bind = {
    description = "Bind ELAN7001 fingerprint sensor to spidev";
    wantedBy = [ "multi-user.target" ];
    before = [ "fprintd.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      dev=/sys/bus/spi/devices/spi-ELAN7001:00
      [ -e "$dev" ] || exit 0
      ${pkgs.kmod}/bin/modprobe spidev
      echo spidev > "$dev/driver_override"
      echo spi-ELAN7001:00 > /sys/bus/spi/drivers_probe
    '';
  };
}
