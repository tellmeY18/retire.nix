{ rot }:
let
  flake = builtins.getFlake "/home/satan/nix-config";
  pkgs = flake.nixosConfigurations.chopper.pkgs;
in
pkgs.libfprint.overrideAttrs (old: {
  pname = "libfprint-imgcap-${rot}";
  postPatch = (old.postPatch or "") + ''
    substituteInPlace libfprint/drivers/elanspi.h --replace-fail \
      '  {.udev_types = 0}' \
      '  {.udev_types = ELANSPI_UDEV_TYPES, .spi_acpi_id = "ELAN7001", .hid_id = {.vid = ELANSPI_TP_VID, .pid = 0x30ef}, .driver_data = ELANSPI_${rot}},
      {.udev_types = 0}'
    substituteInPlace libfprint/drivers/elanspi.c --replace-fail \
      'dev_class->scan_type = FP_SCAN_TYPE_SWIPE;' \
      'dev_class->scan_type = FP_SCAN_TYPE_SWIPE;
        dev_class->temp_hot_seconds = -1;'
  '';
  postInstall = (old.postInstall or "") + ''
    install -Dm755 examples/img-capture $out/bin/fp-img-capture
  '';
})
