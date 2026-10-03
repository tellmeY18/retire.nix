# hosts/skywalker/parts/nvidia.nix — NVIDIA GTX 1060 6GB (Pascal, GP106).
#
# Headless CUDA/compute setup. `services.xserver.videoDrivers` is the
# supported way to select the NVIDIA kernel module + userspace libs; it does
# NOT enable an X server (services.xserver.enable stays false).
#
# `open = false` is mandatory here: the open kernel modules require Turing or
# newer. Pascal must use the proprietary module.
#
# Only nvidia-smi is installed. nvtop / CUDA toolkit / container toolkit are
# deliberately absent — add them when a workload actually needs them.
{ config, lib, ... }:
{
  # GDM login screen: never blank. On this GTX 1060 + 580 legacy driver, the
  # greeter's idle screen-blank (DPMS off -> wake) makes nvidia-drm's atomic
  # commit stall: "Flip event timeout on head 0" within ~3s, then repeating
  # "Failed to apply atomic modeset" and Xid 13 (same shader, class c197,
  # offset 34a4) from gnome-shell until the greeter is restarted. Reproduced
  # on demand by toggling mutter's PowerSaveMode. GDM's default idle-delay is
  # 300s. Scoped to the greeter ONLY: user sessions keep their own blank/lock
  # behaviour (serene's GNOME auto-lock rides on idle-delay, so don't touch it
  # globally). mkBefore: first dconf database wins.
  programs.dconf.profiles.gdm.databases = lib.mkBefore [
    { settings."org/gnome/desktop/session".idle-delay = lib.gvariant.mkUint32 0; }
  ];

  services.xserver.videoDrivers = [ "nvidia" ];

  # Userspace GL/CUDA libraries (formerly hardware.opengl).
  hardware.graphics.enable = true;

  hardware.nvidia = {
    # The GTX 1060 is Pascal (GP106), which the current `production` branch
    # (595.xx) has DROPPED. Booting it there loads the module but finds no
    # device:
    #   NVRM: The GTX 1060 6GB ... is supported through the NVIDIA 580.xx
    #         Legacy drivers ... The 595.91.07 driver will ignore it
    #   NVRM: No NVIDIA GPU found.
    # Pascal's final branch is 580, so pin the legacy_580 package. Do not
    # "upgrade" this to production/stable — that silently disables the GPU.
    package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
    open = false;
    modesetting.enable = true;
    # No suspend/resume dance and no dynamic power management on a box that
    # is always on and always driving a GPU workload.
    powerManagement.enable = false;
    nvidiaSettings = false; # GUI tool — useless headless

    # VA-API video decode/encode. Defaults to true, which drags
    # nvidia-vaapi-driver → GStreamer → ffmpeg → PipeWire → x265 → mesa
    # into the closure (~660 MiB fetched / 2.4 GiB unpacked) for a box that
    # decodes no video. Flip to true if you ever transcode here.
    videoAcceleration = false;
  };

  # Persistence mode: keeps the driver loaded between CUDA processes, so each
  # job doesn't pay the multi-second device re-initialisation cost.
  hardware.nvidia.nvidiaPersistenced = true;

  environment.systemPackages = [
    config.hardware.nvidia.package.bin # nvidia-smi
  ];
}
