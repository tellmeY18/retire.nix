{ pkgs, ... }:
{
  home.packages = with pkgs; [
    pulseaudio # includes paplay, parecord utilities
  ];

  # PulseAudio configuration
  home.file.".config/pulse/default.pa".text = ''
    # Load basic modules
    load-module module-device-restore
    load-module module-stream-restore
    load-module module-card-restore

    # Load macOS CoreAudio support
    load-module module-coreaudio-detect

    # Load protocols
    load-module module-native-protocol-unix
    load-module module-native-protocol-tcp auth-anonymous=1

    # Default device restore
    load-module module-default-device-restore
  '';

  # Optional: daemon configuration for low latency
  home.file.".config/pulse/daemon.conf".text = ''
    default-fragments = 2
    default-fragment-size-msec = 5
    default-sample-rate = 48000
    avoid-resampling = yes
  '';
}
