# home/desktop/widgets.nix — desktop widgets (Quickshell, background layer).
#
# Three workspace-aware sets plus an always-on utility column:
#   home  (any workspace but 2 and 3): clock, calendar, todo, world clocks,
#         system / battery / sound / media / launchers
#   work  (workspace 2): repo status, failed units, ZFS, k3s nodes, pomodoro, notes
#   media (workspace 3): big now-playing, visualiser, output switcher
#   utility (right side, everywhere): toggles, network, top processes,
#         bluetooth, clipboard, screenshots
# Colours come from the live theme (~/.local/state/theme/qs.json), so
# `theme toggle` restyles them without a rebuild.
{ config, lib, pkgs, ... }:

let
  # World clocks ("label" = tz database zone) and countdowns ("label" = date).
  clocks = {
    "UTC" = "UTC";
    "London" = "Europe/London";
    "New York" = "America/New_York";
    "Tokyo" = "Asia/Tokyo";
  };
  countdowns = {
    "new year" = "2027-01-01";
  };

  repo = "${config.home.homeDirectory}/nix-config";

  # Fast (3 s): meters, network counters, top processes, uptime.
  stats = pkgs.writeShellApplication {
    name = "ink-stats";
    runtimeInputs = with pkgs; [ coreutils gawk gnugrep gnused procps networkmanager wireplumber brightnessctl ];
    text = ''
      set +e
      read -r _ u n s i w q sq st _ < /proc/stat
      t1=$((u + n + s + i + w + q + sq + st)); i1=$((i + w))
      sleep 0.4
      read -r _ u n s i w q sq st _ < /proc/stat
      t2=$((u + n + s + i + w + q + sq + st)); i2=$((i + w))
      dt=$((t2 - t1)); [ "$dt" -gt 0 ] || dt=1
      echo "cpu=$((100 * (dt - (i2 - i1)) / dt))"
      awk '/MemTotal/{t=$2} /MemAvailable/{a=$2} END{printf "mem=%d\n", (t-a)*100/t}' /proc/meminfo
      echo "disk=$(df --output=pcent / | tail -n1 | tr -dc 0-9)"
      echo "temp=$(( $(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null || echo 0) / 1000 ))"
      echo "bat=$(cat /sys/class/power_supply/BAT0/capacity 2>/dev/null)"
      echo "status=$(tr '[:upper:]' '[:lower:]' < /sys/class/power_supply/BAT0/status 2>/dev/null)"
      echo "ac=$(cat /sys/class/power_supply/AC0/online 2>/dev/null)"
      echo "ssid=$(nmcli -t -f ACTIVE,SSID dev wifi 2>/dev/null | grep '^yes' | head -n1 | cut -d: -f2-)"
      v=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null)
      echo "vol=$(echo "$v" | awk '{printf "%d", $2*100}')"
      echo "$v" | grep -q MUTED && echo "muted=1" || echo "muted=0"
      echo "bright=$(brightnessctl -m 2>/dev/null | cut -d, -f4 | tr -d '%')"
      sed 's/:/ /' /proc/net/dev | awk 'NR>2 && $1 != "lo" {rx+=$2; tx+=$10} END{printf "rx=%d\ntx=%d\n", rx, tx}'
      ps -eo comm=,pcpu= --sort=-pcpu | awk '$1 != "ps" && n < 3 {n++; printf "top=%s %s%%\n", $1, $NF}'
      awk '{s=int($1); printf "uptime=%dd %dh %dm\n", s/86400, (s%86400)/3600, (s%3600)/60}' /proc/uptime
      echo "kernel=$(uname -r)"
    '';
  };

  # Slow (10 s): repo, units, pools, cluster, toggles, clipboard, shots,
  # bluetooth, world clocks, countdowns.
  slow = pkgs.writeShellApplication {
    name = "ink-slow";
    runtimeInputs = with pkgs; [ coreutils gnugrep gnused gawk procps jujutsu kubectl cliphist dunst bluez ];
    text = ''
      set +e
      export PATH="$PATH:/run/current-system/sw/bin"

      cd ${repo} 2>/dev/null && {
        echo "repoChange=$(jj --ignore-working-copy log -r @ --no-graph -T 'if(description, description.first_line(), "(no description)")' 2>/dev/null)"
        echo "repoFiles=$(jj --ignore-working-copy diff --summary 2>/dev/null | wc -l)"
      }

      echo "failed=$(systemctl --failed --no-legend --plain 2>/dev/null | wc -l)"
      echo "userFailed=$(systemctl --user --failed --no-legend --plain 2>/dev/null | wc -l)"
      zpool list -H -o name,health 2>/dev/null | awk '{print "zfs=" $1 " " $2}'

      kc="''${KUBECONFIG:-$HOME/.kube/config}"
      [ -f "$kc" ] || kc="$HOME/.kube/glug-infra.yaml"
      [ -f "$kc" ] && timeout 4 kubectl --kubeconfig "$kc" get nodes --no-headers 2>/dev/null \
        | awk '{print "k8s=" $1 " " $2}'

      [ "$(dunstctl is-paused 2>/dev/null)" = true ] && echo "dnd=1" || echo "dnd=0"
      pgrep -x hyprsunset >/dev/null && echo "night=1" || echo "night=0"

      cliphist list 2>/dev/null | head -n 4 | cut -c1-90 | sed 's/^/clip=/'
      # shellcheck disable=SC2012
      ls -t "$HOME"/Pictures/Screenshots/*.png 2>/dev/null | head -n 3 | sed 's/^/shot=/'

      bluetoothctl devices Paired 2>/dev/null | while read -r _ mac name; do
        if bluetoothctl info "$mac" 2>/dev/null | grep -q "Connected: yes"; then c=1; else c=0; fi
        echo "bt=$mac|$name|$c"
      done

      ${lib.concatStringsSep "\n      " (lib.mapAttrsToList
        (label: zone: ''echo "tz=${label}|$(TZ=${zone} date +%H:%M)"'') clocks)}
      ${lib.concatStringsSep "\n      " (lib.mapAttrsToList
        (label: date: ''echo "cd=${label}|$(( ( $(date -d ${date} +%s) - $(date +%s) ) / 86400 ))"'') countdowns)}
    '';
  };

  cavaConf = pkgs.writeText "ink-cava.conf" ''
    [general]
    bars = 32
    framerate = 30
    [input]
    method = pipewire
    source = auto
    [output]
    method = raw
    raw_target = /dev/stdout
    data_format = ascii
    ascii_max_range = 100
    bar_delimiter = 59
    frame_delimiter = 10
  '';

  config' = pkgs.runCommand "quickshell-ink" { } ''
    mkdir -p $out
    cp ${./quickshell/ink/shell.qml} $out/shell.qml
  '';
in
{
  programs.quickshell = {
    enable = true;
    configs.ink = config';
    activeConfig = "ink";
    systemd.enable = true;
  };

  systemd.user.services.quickshell.Service = {
    Environment = [
      "INK_STATS=${stats}/bin/ink-stats"
      "INK_SLOW=${slow}/bin/ink-slow"
      "INK_CAVA=${pkgs.cava}/bin/cava"
      "INK_CAVA_CONF=${cavaConf}"
      "PATH=${config.home.profileDirectory}/bin:/run/current-system/sw/bin:/run/wrappers/bin"
    ];
    Restart = lib.mkForce "on-failure";
  };

  # The todo and notes widgets keep their text in plain files.
  home.activation.inkData = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p "${config.xdg.dataHome}/ink"
    run touch "${config.xdg.dataHome}/ink/todo.txt" "${config.xdg.dataHome}/ink/notes.txt"
  '';
}
