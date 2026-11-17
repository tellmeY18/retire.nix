# hosts/chopper/parts/fingerprint.nix — ELAN7001 SPI fingerprint reader.
#
# The sensor (ACPI ELAN7001, Intel LPSS SPI) has no kernel driver; libfprint's
# elanspi driver talks to it through spidev and resets it via the touchpad's
# hidraw node. Upstream's match table lacks this laptop's touchpad (04F3:30EF),
# and its NBIS matcher cannot tell fingers apart on the stitched swipe strips,
# so this builds libfprint from a rebase of upstream that carries the SIGFM
# matcher (OpenCV) and patches elanspi to use it.
{ pkgs, ... }:
let
  libfprint = pkgs.libfprint.overrideAttrs (old: {
    pname = "libfprint-sigfm";
    src = pkgs.fetchFromGitHub {
      owner = "archeYR";
      repo = "libfprint-CS9711";
      rev = "3c93fc2da6347624fc9c2d2f36a38fec64f99835";
      hash = "sha256-cZItBY2VEvuOimT8IP4SaZaNlzXtc+d+Fw3Tk3Lx5+s=";
    };
    patches = (old.patches or [ ]) ++ [ ./libfprint-elanspi-sigfm.patch ];
    buildInputs = old.buildInputs ++ [ pkgs.opencv pkgs.doctest ];
    # meson runs tests/unittest_inspector.py at configure time, which imports gi.
    nativeBuildInputs = old.nativeBuildInputs ++ [
      (pkgs.python3.withPackages (p: [ p.pygobject3 ]))
    ];
    # sigfm's own tests don't pass in the sandbox (see the CS9711 AUR notes).
    doInstallCheck = false;
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
