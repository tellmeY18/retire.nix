# Runbook: Adding a k3s Server Node

This runbook explains how to join a second (or third) k3s **server** node
to the chopper cluster, discusses the etcd quorum implications at each step,
and explains how to flip CNPG pod scheduling from preferred to required
anti-affinity once the cluster has enough nodes.

---

> **⚠ 2-node etcd quorum trap — read this first**
>
> etcd requires an **odd majority** to elect a leader.
>
> | Nodes | etcd quorum | Tolerates |
> |---|---|---|
> | 1 | 1 of 1 | nothing (any loss = cluster down) |
> | **2** | **2 of 2** | **nothing** (losing either node = cluster read-only / stuck) |
> | 3 | 2 of 3 | **1 node loss** |
>
> **A 2-node cluster gives you zero additional fault tolerance over a
> 1-node cluster for the Kubernetes control plane.**  Both nodes must be
> healthy for writes to succeed.  The only benefit of adding a second
> workload node before the third is spreading CNPG pods for pod-level
> redundancy (a pod crash on one node does not take out the other).
>
> **Target architecture: 3 nodes.**  If you only have 2 laptops today,
> consider running a third node on a tiny always-on VPS (1 vCPU / 512 MB
> is enough) as a quorum-only tiebreaker.  Taint it so workloads never
> schedule there.

---

## Prerequisites

- The new machine has NixOS installed and is accessible over the tailnet.
- `modules/services/k3s.nix` is imported by the new host's configuration
  with `role = "server"` (not `"server-init"` — that is only for the
  first node).
- The k3s join token is in sops: `secrets/chopper/k3s-token`.
  `sops-nix` will decrypt it at activation time.
- Firewall on the new node allows k3s ports **only on `tailscale0`** (this
  should already be set by `profiles/k3s-node.nix`).

---

## Step 1 — Note the existing cluster's server URL and token

On chopper (the existing server-init node):

```shell
# Server URL (use the tailscale FQDN, not 127.0.0.1).
# Replace <tailnet> with your tailnet name (e.g. tailb3ef6.ts.net).
echo "https://chopper.<tailnet>.ts.net:6443"

# Verify the join token is in place.
sudo cat /run/secrets/k3s-token   # sops-nix runtime path
```

---

## Step 2 — Deploy NixOS on the new node

Follow the standard NixOS bootstrap for your hardware.  Ensure the new host's
`metadata.nix` has:

```nix
{
  hostname = "node2";           # or whatever you name it
  system   = "x86_64-linux";
  roles    = [ "k3s" ];         # pulls in profiles/k3s-node.nix
}
```

And in `hosts/node2/configuration.nix` (via `modules/services/k3s.nix`):

```nix
services.k3s-cluster = {
  enable        = true;
  role          = "server";           # NOT "server-init"
  serverAddr    = "https://chopper.<tailnet>.ts.net:6443";
  tokenFile     = config.sops.secrets."k3s-token".path;
  clusterInit   = false;
};
```

Apply the configuration:

```shell
nh os switch /path/to/flake#node2   # or nixos-rebuild switch --flake ...
```

---

## Step 3 — Verify the node joined

From any machine with `kubectl` access:

```shell
# The new node should appear within ~60 seconds of k3s starting.
kubectl get nodes -o wide

# Check etcd member list.
kubectl -n kube-system exec -it etcd-chopper -- \
  etcdctl --endpoints=https://127.0.0.1:2379 \
  --cacert=/var/lib/rancher/k3s/server/tls/etcd/server-ca.crt \
  --cert=/var/lib/rancher/k3s/server/tls/etcd/server-client.crt \
  --key=/var/lib/rancher/k3s/server/tls/etcd/server-client.key \
  member list -w table

# All members should show "started" and "false" for isLearner.
```

---

## Step 4 — (3-node only) Taint the quorum-only node

If the third node is a VPS used purely as an etcd tiebreaker, taint it so
workloads (especially CNPG) never schedule there:

```shell
kubectl taint nodes <quorum-node-name> \
  node-role.kubernetes.io/control-plane:NoSchedule \
  quorum-only=true:NoExecute
```

---

## Step 5 — Flip CNPG Cluster + Pooler affinity to required

Once you have **≥ 2 nodes that can run workloads** (i.e. 2 untainted nodes),
edit the Helm values in `k8s/apps/postgres/values.yaml`:

```yaml
# BEFORE (Phase 1 — single node):
cluster:
  affinity:
    podAntiAffinityType: preferred
    topologyKey: kubernetes.io/hostname

poolers:
  - name: rw
    template:
      spec:
        affinity:
          podAntiAffinity:
            preferredDuringSchedulingIgnoredDuringExecution:
              - weight: 100
                podAffinityTerm:
                  labelSelector: { matchLabels: { cnpg.io/poolerName: postgres-pooler-rw } }
                  topologyKey: kubernetes.io/hostname

# AFTER (Phase 2+ — multiple nodes):
cluster:
  affinity:
    podAntiAffinityType: required
    topologyKey: kubernetes.io/hostname

poolers:
  - name: rw
    template:
      spec:
        affinity:
          podAntiAffinity:
            requiredDuringSchedulingIgnoredDuringExecution:
              - labelSelector: { matchLabels: { cnpg.io/poolerName: postgres-pooler-rw } }
                topologyKey: kubernetes.io/hostname
```

Apply the change. helmfile diff first, then sync:

```shell
just k8s-diff           # preview the rolling-restart impact
just k8s-apply          # CNPG performs a rolling restart respecting PDBs
kubectl get pods -n cnpg-clusters -o wide -w
```

---

## Step 6 — Verify CNPG pod distribution

```shell
# Each CNPG pod should be on a different node.
kubectl get pods -n cnpg-clusters -o wide

# Cluster should be healthy with all instances Running.
kubectl cnpg status postgres -n cnpg-clusters
```

---

## Step 7 — Update kubeconfig TLS SANs (if needed)

If you want `kubectl` to reach the apiserver via the second node's FQDN when
chopper is down, ensure both FQDNs are in the k3s TLS SANs.  Add the new
node's tailscale FQDN to `k3s-cluster.extraFlags` in `modules/services/k3s.nix`:

```nix
extraFlags = [
  "--tls-san=chopper.<tailnet>.ts.net"
  "--tls-san=node2.<tailnet>.ts.net"
];
```

Then `nixos-rebuild` on all server nodes and update your local `~/.kube/config`
to list both server addresses.

---

## Post-add-node checklist

- [ ] `kubectl get nodes` shows all nodes as `Ready`.
- [ ] etcd member list shows all members as `started` / not learner.
- [ ] CNPG pods spread across nodes (`kubectl get pods -n cnpg-clusters -o wide`).
- [ ] `kubectl cnpg status postgres -n cnpg-clusters` is healthy.
- [ ] WAL archiving still active.
- [ ] Tailscale `pg-rw` device is registered and reachable.
- [ ] Affinity updated from `preferred` → `required` in both Cluster and Pooler.
- [ ] (3-node) Quorum node tainted; CNPG pods do NOT land on it.
