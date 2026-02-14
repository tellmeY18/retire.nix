{ config, pkgs, ... }:
{
  home.packages = with pkgs; [
    pulseaudio  # includes paplay, parecord utilities
  ];

  # PulseAudio configuration
  home.file.".config/pulse/default.pa".text = ''
    .include ${pkgs.pulseaudio}/etc/pulse/default.pa

    # Load TCP module for network access
    load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1
  '';

  # Optional: daemon configuration for low latency
  home.file.".config/pulse/daemon.conf".text = ''
    default-fragments = 2
    default-fragment-size-msec = 5
    default-sample-rate = 48000
    avoid-resampling = yes
  '';
}
