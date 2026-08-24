---
name: post-flake-update-health
description: Verify a host (or the whole k3s fleet: chopper, c3po, kenobi) is actually healthy after `nix flake update` + deploy — new generation booted (not just activated), no failed units, k3s/etcd quorum intact, ZFS pools healthy. Use whenever asked to check node health after a flake update/deploy, or "did the update apply".
---

# Post-flake-update health check

A deploy can report success while the host is still running the OLD kernel/
generation (activation succeeded but no reboot happened), or while quorum is
degraded. Check all of these, don't stop at `systemctl is-system-running`.

Node tailnet hostnames: `chopper.tail477f2f.ts.net`, `c3po.tail477f2f.ts.net`,
`kenobi.tail477f2f.ts.net`. SSH as `root`. `tailscale status` can show a node
as "offline" when it's actually reachable — don't trust it, SSH directly.

## Per-host checks

```sh
ssh root@<host>.tail477f2f.ts.net '
  echo "== system =="; systemctl is-system-running; systemctl --failed --no-legend
  echo "== generation booted vs current =="
  diff <(readlink /run/booted-system) <(readlink /run/current-system) \
    && echo "OK: booted == current" \
    || echo "REBOOT NEEDED: activated but not booted into new generation"
  echo "== kernel =="; uname -r
  echo "== zfs =="; zpool status -x
'
```

- `booted-system != current-system` means `switch` activated the new
  generation but the machine hasn't rebooted — expected for most changes
  (no reboot needed unless kernel/initrd/bootloader changed), but flag it
  so the user knows a reboot is pending if they want the new kernel live.
- `systemctl --failed` must be empty.
- `zpool status -x` must say "all pools are healthy".

## Cluster-wide checks (chopper/c3po/kenobi are one k3s cluster)

Run from kenobi (the control-plane/etcd node) or via the HA LB:

```sh
ssh root@kenobi.tail477f2f.ts.net '
  k3s kubectl get nodes -o wide          # all Ready, matching k8s/containerd versions
  k3s kubectl get --raw /healthz         # want "ok"
'
```

- All three nodes `Ready`.
- Compare `NixOS` / kernel version column across nodes — mismatched
  versions after a fleet-wide flake update means one node didn't get
  deployed or needs a reboot to pick up the new kernel.
- If a node's k3s is an **agent** (not `control-plane,etcd` in ROLES), its
  own `k3s kubectl get nodes` will fail with `connection refused` on its
  own IP:6443 — that's expected, it talks to the server (`--server` flag in
  `/etc/systemd/system/k3s.service`), not itself. Query kenobi instead.

## Quick fleet one-liner

```sh
for h in chopper c3po kenobi; do
  echo "=== $h ==="
  ssh root@$h.tail477f2f.ts.net 'systemctl is-system-running; systemctl --failed --no-legend; diff <(readlink /run/booted-system) <(readlink /run/current-system) >/dev/null && echo "booted==current" || echo "REBOOT PENDING"; zpool status -x'
done
