---
name: deploy-k3s-nodes
description: Safely deploy NixOS config changes to this repo's k3s cluster nodes (chopper, c3po, kenobi) with deploy-rs, without wedging activation or breaking the HA control plane. Use whenever running `just deploy <host>` / `nix run .#deploy-rs` for chopper, c3po, or kenobi, or when a deploy got stuck ("Could not acquire lock", magic-rollback timeout, k3s/etcd unhealthy after a deploy).
---

# Deploying the k3s cluster nodes (chopper / c3po / kenobi)

These three nodes are **k3s servers with embedded etcd** (control-plane + etcd,
quorum = 2 of 3) and they run the production MySQL (MGR) + Postgres + apps.
Deploys here have two recurring traps that have caused real outages. Follow
this procedure exactly.

Node tailnet IPs: `chopper=100.107.213.17`, `kenobi=100.73.101.89`,
`c3po=100.109.132.76`. SSH user is `root`. HA kube endpoint:
`https://k3s-cp.tail477f2f.ts.net:6443` (a Tailscale LB across all 3 apiservers).

## The two traps (why deploys get stuck)

1. **magic-rollback timeout → churn.** `deploy-rs` defaults to `--magic-rollback`,
   which activates the new generation then SSHes back to confirm within a
   timeout. These nodes' networking (tailscale/dbus) briefly blips during
   activation, so the confirmation often fails → deploy-rs **rolls back** and
   re-activates the previous generation. The rollback + retries restart
   k3s/etcd several times rapidly and can wedge a node's etcd member.
   **Always deploy with `--magic-rollback false`.**

2. **systemd units with no `path` → activation failure / infinite wedge.**
   Units like `k3s-pod-routes.service` and (c3po) `tailscale-online.service`
   shell out to `ip`, `sh`, `timeout`, `grep`, `sleep`. If the unit has no
   `path = [ ... ]`, those binaries aren't found:
   - `tailscale-online` exits 127 → activation fails → rollback.
   - `k3s-pod-routes` ExecStartPre (`until ip link show tailscale0 ... UP`)
     loops forever (stderr swallowed) → `switch-to-configuration` never
     finishes → holds the activation lock → every future deploy fails with
     **"Could not acquire lock"**.
   Any new/edited unit that runs shell tools MUST declare its `path`
   (e.g. `path = [ pkgs.iproute2 pkgs.coreutils pkgs.bash pkgs.gnugrep ];`).

## Pre-flight (before deploying ANY of the 3 nodes)

```sh
# 1) The config must evaluate.
nix eval .#nixosConfigurations.<host>.config.system.build.toplevel.drvPath >/dev/null && echo OK

# 2) Control plane must have quorum on the OTHER nodes (deploy ONE at a time).
#    Query a node you are NOT about to deploy, directly (bypass the LB):
kubectl --server=https://<other-node-ip>:6443 --insecure-skip-tls-verify get --raw=/readyz

# 3) If this host runs a MySQL MGR member, confirm the group is 3 ONLINE first
#    (losing the member you bounce must leave a majority):
#    just k8s::mgr-status   (or query performance_schema.replication_group_members)

# 4) The target node must be lock-free (no leftover wedge from a prior deploy):
ssh root@<host-ip> 'ps aux | grep -E "switch-to-conf|deploy-rs.*activate" | grep -v grep | wc -l'   # want 0
```

Never deploy two control-plane/etcd nodes at once. Bounce one, verify it
rejoins, then do the next.

## Deploy

```sh
# NOT `just deploy` (it can't pass extra flags). Call deploy-rs directly:
nix run .#deploy-rs -- .#<host> --skip-checks --magic-rollback false
```

Success looks like `⭐ Activation succeeded!` + `🚀 Success activating, done!`.

## If a deploy gets stuck ("Could not acquire lock" / wedged)

A wedged `switch-to-configuration` (usually blocked on `k3s-pod-routes`'s
`until ip link ... UP` loop) holds the lock. Clear it, then redeploy:

```sh
ssh root@<host-ip> '
  pkill -9 -f "until ip link show tailscale0"
  pkill -9 -f "switch-to-configuration"
  pkill -9 -f "deploy-rs.*activate"
'
# (SSH may drop as networking settles — reconnect and confirm 0 switch procs)
ssh root@<host-ip> 'ps aux | grep switch-to-conf | grep -v grep | wc -l'   # want 0
# then redeploy with --magic-rollback false
```

If the root cause is a missing `path` on a unit, FIX THAT in
`hosts/<host>/parts/network.nix` (or wherever the unit is defined) before
redeploying — otherwise it will wedge again on the next activation.

## Post-deploy verification (every time)

```sh
ssh root@<host-ip> '
  systemctl is-active k3s k3s-pod-routes tailscale-online 2>/dev/null
  ip route show | grep 10.42                 # cross-node pod routes present
  journalctl -u k3s --since "30 seconds ago" --no-pager | \
    grep -icE "deadline exceeded|future revision|handshake failed"   # want 0
'
# HA endpoint must be reliably healthy (not intermittent):
ok=0; for i in $(seq 1 6); do kubectl --server=https://k3s-cp.tail477f2f.ts.net:6443 get --raw=/readyz >/dev/null 2>&1 && ok=$((ok+1)); sleep 1; done; echo "readyz $ok/6"
```

## If a node's etcd is wedged after deploy

Symptoms: that node's `k3s` stays `activating`; logs show
`authentication handshake failed: context deadline exceeded`,
`failed to publish local member to cluster through raft`, or
`required revision is a future revision`; the `k3s-cp` LB returns
intermittent `ServiceUnavailable` (it round-robins onto the bad apiserver).

The other two nodes still hold quorum and serve — point kubectl at a healthy
node directly (`--server=https://<healthy-ip>:6443 --insecure-skip-tls-verify`)
to keep visibility. Then give the wedged member a clean rejoin:

```sh
ssh root@<host-ip> 'systemctl restart k3s'
# wait ~45s, then re-run post-deploy verification; readyz should go 6/6.
```

## kubeconfig note

`~/.kube/glug-infra.yaml` must point at the HA endpoint
`https://k3s-cp.tail477f2f.ts.net:6443`, NOT a single node's IP. If it's pinned
to one node, kubectl breaks whenever that node is down. Reset with
`just kubeconfig` or:
`kubectl config set-cluster <cluster> --server=https://k3s-cp.tail477f2f.ts.net:6443`.
