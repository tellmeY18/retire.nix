# modules/services/k3s.nix
#
# Higher-level NixOS module that wraps nixpkgs `services.k3s` with a
# `services.k3s-cluster` option set tuned for a Tailscale-only homelab cluster.
#
# Design goals:
#   - All inter-node traffic (etcd, apiserver, kubelet, flannel) rides tailscale0.
#   - Bootstrap-critical operators (OpenEBS ZFS LocalPV, Tailscale operator) are
#     declared as k3s HelmChart CRs so they come up automatically after every reboot
#     without any manual `helmfile` run.
#   - The Tailscale operator's OAuth credentials are NOT written through the Nix
#     store (which is world-readable); they are handled by the companion module
#     modules/services/k3s-bootstrap-manifests.nix via sops-nix.
#
# Usage (in a host configuration):
#
#   imports = [
#     inputs.sops-nix.nixosModules.sops
#     ../../modules/services/k3s.nix
#     ../../modules/services/k3s-bootstrap-manifests.nix
#   ];
#
#   services.k3s-cluster = {
#     enable     = true;
#     role       = "server-init";   # first/only server
#     clusterInit = true;
#     tokenFile  = config.sops.secrets.k3s-token.path;
#     nodeIP     = "100.x.y.z";    # static tailscale IP for this host
#   };
#
#   sops.secrets.k3s-token.sopsFile = ../../secrets/chopper/k3s-token;

{ config
, lib
, ...
}:

let
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    optionals
    elem
    types
    ;

  cfg = config.services.k3s-cluster;
in
{
  # Pull in the companion module that handles the Tailscale OAuth Secret.
  # Kept separate so the secret-writing logic is auditable in isolation, but
  # always imported together with this module so hosts need only one import.
  imports = [ ./k3s-bootstrap-manifests.nix ];

  options.services.k3s-cluster = {

    enable = mkEnableOption "k3s cluster node (homelab, Tailscale-only)";

    role = mkOption {
      type = types.enum [
        "server-init"
        "server"
        "agent"
        "quorum"
      ];
      default = "server-init";
      description = ''
        Cluster role for this node.
          server-init — first control-plane node; sets --cluster-init (embedded etcd).
          server       — additional control-plane nodes that join an existing cluster.
          agent        — worker-only; no control-plane components.
          quorum       — control-plane + etcd only; tainted so no workloads schedule here.
                         Use for a cheap always-on tiebreaker (VPS / Pi) to reach true
                         3-node etcd quorum without landing CNPG pods there.
      '';
    };

    tailscaleInterface = mkOption {
      type = types.str;
      default = "tailscale0";
      description = ''
        Network interface used for all cluster traffic (flannel overlay, etcd peers,
        apiserver). Must be the Tailscale interface so all traffic is WireGuard-encrypted
        and never touches the public interface.
      '';
    };

    clusterInit = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Pass --cluster-init to k3s, bootstrapping a new embedded-etcd cluster.
        Set to true on exactly ONE server-init node. Subsequent servers join via
        serverAddr instead.
      '';
    };

    serverAddr = mkOption {
      type = types.str;
      default = "";
      example = "https://chopper:6443";
      description = ''
        URL of an existing server for joining nodes (servers and agents).
        Leave empty on the cluster-init node. Use the Tailscale FQDN or IP so the
        connection is always WireGuard-encrypted.
      '';
    };

    tokenFile = mkOption {
      type = types.path;
      description = ''
        Path to the cluster join token file at runtime.
        Should point to a sops-nix decrypted secret, e.g.:
          config.sops.secrets.k3s-token.path
        The file must contain only the raw token string.
      '';
    };

    nodeName = mkOption {
      type = types.str;
      default = config.networking.hostName;
      description = ''
        Node name registered in Kubernetes. Defaults to the NixOS hostname.
        Override if the hostname contains uppercase letters (Kubernetes node names
        must be lowercase RFC-1123 labels).
      '';
    };

    nodeIP = mkOption {
      type = types.str;
      default = "";
      example = "100.64.0.1";
      description = ''
        Static Tailscale IP of this node. When non-empty, passes
        --node-ip, --bind-address, and --advertise-address to k3s so that the
        apiserver, etcd, and flannel all bind to the tailnet interface rather than
        the default (which would pick the primary physical interface).

        This value rarely changes on a homelab tailnet (Tailscale tends to keep the
        same IP per device), so it is safe to declare statically here.

        If you prefer to derive it dynamically at runtime, leave this empty and
        write a systemd ExecStartPre script to populate
        /etc/rancher/k3s/config.yaml before k3s starts — see the comment below.

        # --node-ip / --bind-address / --advertise-address cannot be set statically
        # here because the Tailscale IP is only known at runtime.
        # These are configured via /etc/rancher/k3s/config.yaml written by a
        # systemd oneshot in modules/services/k3s-bootstrap-manifests.nix, or set
        # in hosts/<name>/k3s-config.yaml.
      '';
    };

    extraFlags = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = ''
        Additional flags passed verbatim to the k3s binary.
        Use this for anything not covered by the options above.
      '';
    };

    openebsZfsPool = mkOption {
      type = types.str;
      default = "rpool/openebs";
      example = "tank/k8s-volumes";
      description = ''
        Name of the ZFS dataset that the OpenEBS ZFS LocalPV provisioner will
        carve PVs out of, on this node. Used as the `poolname` parameter on
        the cluster-wide `zfs-localpv` StorageClass manifest.

        The dataset must be pre-created on every node that hosts CNPG
        instances; the provisioner will not create it. Recommended
        properties:
          recordsize=8K  logbias=throughput  compression=zstd
          xattr=sa  atime=off

        IMPORTANT: this value is rendered into a *single* cluster-wide
        StorageClass. All k3s nodes that participate in CNPG storage MUST
        therefore use the same dataset NAME (the actual zpool can differ,
        e.g. one node uses `rpool/openebs` and another uses `tank/openebs`,
        only if both nodes' datasets are renamed to a single common name
        before joining the cluster). When in doubt, keep the default and
        create `rpool/openebs` on every node.
      '';
    };

  };

  config = mkIf cfg.enable {

    # -----------------------------------------------------------------------
    # Private registry — allow HTTP for the in-cluster Nixery instance.
    #
    # k3s containerd defaults to HTTPS for all registries. Nixery runs on
    # the tailnet over plain HTTP (port 8080), so we must explicitly mark
    # it as insecure (http-only). Without this, image pulls fail with:
    #   "http: server gave HTTP response to HTTPS client"
    #
    # Uses a dedicated oneshot (not preStart) to avoid conflicts with
    # per-host preStart scripts (e.g. kenobi's flannel cleanup).
    #
    # Ref: https://docs.k3s.io/installation/private-registry
    # -----------------------------------------------------------------------
    systemd.services.k3s-registries = {
      description = "Write k3s private registry config";
      before = [ "k3s.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        mkdir -p /etc/rancher/k3s
        cat > /etc/rancher/k3s/registries.yaml <<'EOF'
        mirrors:
          "nixery.tail477f2f.ts.net:8080":
            endpoint:
              - "http://nixery.tail477f2f.ts.net:8080"
        EOF
      '';
    };

    # -----------------------------------------------------------------------
    # Underlying services.k3s configuration
    # -----------------------------------------------------------------------
    services.k3s = {
      enable = true;

      # "quorum" nodes are control-plane (server) but tainted so that no
      # workloads (including CNPG) schedule onto them.
      role =
        if
          elem cfg.role [
            "server-init"
            "server"
            "quorum"
          ]
        then
          "server"
        else
          "agent";

      clusterInit = cfg.clusterInit;
      tokenFile = cfg.tokenFile;
      serverAddr = cfg.serverAddr;

      extraFlags =
        let
          isServer = elem cfg.role [
            "server-init"
            "server"
            "quorum"
          ];
        in
        lib.concatStringsSep " " (
          # ── Flags valid for BOTH server and agent ──
          [
            "--node-name=${cfg.nodeName}"
            "--flannel-iface=${cfg.tailscaleInterface}"
          ]

          # ── Server-only flags ──
          ++ optionals isServer [
            # Embedded containerd image registry mirror.
            "--embedded-registry"
            # Make kubeconfig group-readable for wheel users.
            "--write-kubeconfig-mode=0640"
            # Disable components we replace with our own.
            "--disable=traefik,servicelb,local-storage"
            # Disable NetworkPolicy enforcement — the tailnet IS the security
            # boundary. kube-router's ipset-based policy enforcement doesn't
            # work reliably with host-gw over Tailscale (can't match remote
            # pod IPs to namespaces for cross-node traffic).
            "--disable-network-policy"
            # host-gw backend — direct IP routing via tailscale0, no vxlan
            # encapsulation. Eliminates MTU/fragmentation issues from
            # double-encapsulation (vxlan inside wireguard).
            "--flannel-backend=host-gw"
          ]

          # Quorum-only nodes: taint so workloads never schedule here.
          ++ optionals (cfg.role == "quorum") [
            "--node-taint=node-role.kubernetes.io/control-plane:NoSchedule"
            "--node-taint=quorum-only=true:NoExecute"
          ]

          # Static tailscale IP — bind k3s traffic to the tailnet interface.
          # --advertise-address is server-only (apiserver bind).
          ++ optionals (cfg.nodeIP != "") (
            [
              "--node-ip=${cfg.nodeIP}"
              "--bind-address=${cfg.nodeIP}"
            ]
            ++ optionals isServer [
              "--advertise-address=${cfg.nodeIP}"
            ]
          )

          ++ cfg.extraFlags
        );

      # -----------------------------------------------------------------------
      # Bootstrap manifests — k3s applies everything under
      # /var/lib/rancher/k3s/server/manifests/ on every boot, acting as a
      # built-in GitOps loop for cluster-critical operators.
      # -----------------------------------------------------------------------
      manifests = {

        # --------------------------------------------------------------------
        # OpenEBS ZFS LocalPV — CSI driver only
        #
        # IMPORTANT: this chart installs ONLY the CSI driver, controller, and
        # per-node DaemonSet. It does NOT create a StorageClass — the
        # `storageClass.*` values keys do not exist in chart 2.6.2 (verified
        # against the upstream values.yaml). The StorageClass is therefore
        # declared as a separate manifest below (`zfs-localpv-storageclass`).
        #
        # Pool must be pre-created on the host:
        #   zfs create -o mountpoint=none rpool/openebs
        # Recommended dataset properties (set on rpool/openebs):
        #   recordsize=8K   (matches PostgreSQL page size)
        #   logbias=throughput
        #   compression=zstd
        #   xattr=sa
        #   atime=off
        # --------------------------------------------------------------------
        "helmchart-openebs-zfs-localpv".content = {
          apiVersion = "helm.cattle.io/v1";
          kind = "HelmChart";
          metadata = {
            name = "openebs-zfs-localpv";
            namespace = "kube-system";
          };
          spec = {
            repo = "https://openebs.github.io/zfs-localpv";
            chart = "zfs-localpv";
            version = "2.6.2";
            targetNamespace = "openebs";
            createNamespace = true;
            # valuesContent is a raw YAML string passed directly to Helm.
            valuesContent = ''
              zfsNode:
                kubeletDir: /var/lib/kubelet
              zfs:
                bin: /run/current-system/sw/bin/zfs
            '';
          };
        };

        # --------------------------------------------------------------------
        # StorageClass for OpenEBS ZFS LocalPV
        #
        # k3s applies this manifest unconditionally on every boot, so the
        # cluster always has a default StorageClass even if someone
        # accidentally deletes it. The provisioner string `zfs.csi.openebs.io`
        # MUST match the CSIDriver name created by the chart above.
        #
        # Annotations:
        #   storageclass.kubernetes.io/is-default-class=true
        #     New PVCs without an explicit storageClassName get this class.
        #     k3s ships `local-path` as the default; this annotation makes
        #     zfs-localpv the default instead. Both can coexist; PVCs that
        #     name `local-path` explicitly still work.
        #
        # Parameters:
        #   poolname    — ZFS dataset that backs the volumes (must exist).
        #   fstype      — zfs (the dataset itself is the filesystem).
        #   recordsize  — inherited from the parent dataset; explicitly set
        #                  here too so future PVs are predictable.
        #   compression — inherited; declared for the same reason.
        #
        # volumeBindingMode: WaitForFirstConsumer
        #   Don't allocate the ZFS dataset until a Pod is actually scheduled,
        #   so volume placement follows pod placement (single-node today,
        #   per-node-locality once a 2nd node joins).
        # --------------------------------------------------------------------
        "openebs-zfs-localpv-storageclass".content = {
          apiVersion = "storage.k8s.io/v1";
          kind = "StorageClass";
          metadata = {
            name = "zfs-localpv";
            annotations = {
              "storageclass.kubernetes.io/is-default-class" = "true";
            };
          };
          provisioner = "zfs.csi.openebs.io";
          allowVolumeExpansion = true;
          reclaimPolicy = "Delete";
          volumeBindingMode = "WaitForFirstConsumer";
          parameters = {
            poolname = cfg.openebsZfsPool;
            fstype = "zfs";
            recordsize = "8k";
            compression = "zstd";
          };
          # Restrict PV provisioning to storage nodes ONLY.
          # Compute nodes (cloud VMs) will never have PVCs scheduled to them.
          allowedTopologies = [
            {
              matchLabelExpressions = [
                {
                  key = "node-role.glug.infra/storage";
                  values = [ "true" ];
                }
              ];
            }
          ];
        };

        # --------------------------------------------------------------------
        # StorageClass for MySQL / InnoDB workloads (16K recordsize)
        #
        # InnoDB uses a 16KB page size (vs PostgreSQL's 8KB). Matching the
        # ZFS recordsize to the database page size avoids read/write
        # amplification: a single InnoDB page read or write maps 1:1 to a
        # single ZFS record, eliminating partial-record I/O.
        #
        # Both StorageClasses share the same underlying ZFS pool
        # (cfg.openebsZfsPool, default rpool/openebs). OpenEBS ZFS LocalPV
        # applies the SC's `recordsize` parameter to each child dataset it
        # creates, overriding the parent dataset's default.
        #
        # This SC is NOT marked as the default (no annotation). PVCs must
        # explicitly request `storageClassName: zfs-localpv-16k`.
        # --------------------------------------------------------------------
        "openebs-zfs-localpv-storageclass-16k".content = {
          apiVersion = "storage.k8s.io/v1";
          kind = "StorageClass";
          metadata = {
            name = "zfs-localpv-16k";
          };
          provisioner = "zfs.csi.openebs.io";
          allowVolumeExpansion = true;
          reclaimPolicy = "Delete";
          volumeBindingMode = "WaitForFirstConsumer";
          parameters = {
            poolname = cfg.openebsZfsPool;
            fstype = "zfs";
            recordsize = "16k";
            compression = "zstd";
          };
          # Restrict PV provisioning to storage nodes ONLY.
          allowedTopologies = [
            {
              matchLabelExpressions = [
                {
                  key = "node-role.glug.infra/storage";
                  values = [ "true" ];
                }
              ];
            }
          ];
        };

        # --------------------------------------------------------------------
        # Tailscale Kubernetes Operator
        #
        # Exposes in-cluster Services as Tailscale devices with stable MagicDNS
        # names. The CNPG -rw Service (or its PgBouncer Pooler) is exposed via a
        # LoadBalancer Service with `loadBalancerClass: tailscale`, giving cloud
        # webservices a stable `pg-rw.<tailnet>.ts.net:5432` endpoint.
        #
        # OAuth credentials are intentionally left empty here — the operator
        # reads them from the `operator-oauth` Secret in the `tailscale` namespace,
        # which is written at boot by the k3s-tailscale-oauth-secret systemd
        # oneshot in modules/services/k3s-bootstrap-manifests.nix.
        # That service reads from /run/secrets/ (sops-nix), never from the
        # Nix store (which is world-readable at /nix/store/...).
        # --------------------------------------------------------------------
        "helmchart-tailscale-operator".content = {
          apiVersion = "helm.cattle.io/v1";
          kind = "HelmChart";
          metadata = {
            name = "tailscale-operator";
            namespace = "kube-system";
          };
          spec = {
            repo = "https://pkgs.tailscale.com/helmcharts";
            chart = "tailscale-operator";
            # NOTE: Tailscale's chart index skips x.y.0 patches — the lowest
            # 1.76.x they publish is 1.76.1 (see
            # https://pkgs.tailscale.com/helmcharts/index.yaml). When bumping,
            # always cross-check the index.yaml above before changing this.
            version = "1.96.5";
            targetNamespace = "tailscale";
            createNamespace = true;
            valuesContent = ''
              operatorConfig:
                defaultTags:
                  - "tag:k8s"
              oauth:
                clientId: ""
                clientSecret: ""
            '';
          };
        };

      };
    };

    # -------------------------------------------------------------------------
    # Systemd ordering
    #
    # k3s must start after tailscaled is fully up, not just after the unit file
    # is loaded. `requires` ensures k3s stops if tailscaled stops (e.g. during
    # a tailscale update), preventing a split-brain where k3s is running but
    # etcd peers are unreachable.
    # -------------------------------------------------------------------------
    systemd.services.k3s = {
      after = [
        "tailscaled.service"
        "network-online.target"
      ];
      requires = [ "tailscaled.service" ];
    };

    # -------------------------------------------------------------------------
    # Tmpfiles
    #
    #   /var/lib/rancher/k3s — ensure the k3s data directory exists before the
    #     service starts. Mode 0750: only root and the k3s process need to
    #     traverse this tree.
    #
    #   /etc/rancher/k3s     — k3s writes k3s.yaml here at startup, owned by
    #     root:root. We pre-create the directory as 2750 root:wheel: the setgid
    #     bit (2xxx) is critical — it makes the kubeconfig inherit group
    #     `wheel` automatically on every k3s restart, so the 0640 file mode
    #     (set via --write-kubeconfig-mode in extraFlags) translates to
    #     "readable by any wheel-group user". Without setgid, the file would
    #     be created group=root and `wheel` users would still need sudo.
    #
    #     `Z` (capital) ensures the existing path's mode/ownership are
    #     re-asserted on every boot in case k3s ever clobbers them.
    # -------------------------------------------------------------------------
    systemd.tmpfiles.rules = [
      "d /var/lib/rancher/k3s 0750 root root -"
      "Z /etc/rancher/k3s 2750 root wheel -"
    ];

    # -------------------------------------------------------------------------
    # Kernel modules
    #
    # br_netfilter — required so that bridged (same-node pod-to-pod) traffic
    #   passes through iptables. Without this module loaded,
    #   net.bridge.bridge-nf-call-iptables has no effect and kube-proxy's
    #   ClusterIP DNAT rules won't apply to intra-bridge traffic.
    # overlay      — required by containerd's default snapshotter.
    # -------------------------------------------------------------------------
    boot.kernelModules = [
      "br_netfilter"
      "overlay"
    ];

    # -------------------------------------------------------------------------
    # Sysctl — network forwarding & bridge netfilter
    #
    # k3s sets these at runtime, but declaring them in NixOS ensures they
    # are applied early at boot and survive firewall reloads during
    # `nixos-rebuild switch` (which flushes and rebuilds iptables rules,
    # potentially before k3s re-inserts its own).
    # -------------------------------------------------------------------------
    boot.kernel.sysctl = {
      "net.ipv4.ip_forward" = 1;
      "net.ipv6.conf.all.forwarding" = 1;
      "net.bridge.bridge-nf-call-iptables" = 1;
      "net.bridge.bridge-nf-call-ip6tables" = 1;
    };

    # -------------------------------------------------------------------------
    # Firewall — trust CNI interfaces
    #
    # The NixOS iptables-based firewall manages the INPUT chain; it does NOT
    # filter FORWARD by default. Adding cni0 to trustedInterfaces ensures
    # pods can reach host-level services (kubelet on 10250, apiserver on 6443,
    # node-local DNS, etc.) without opening those ports globally.
    #
    #   cni0      — flannel's local bridge (same-node pod ↔ host traffic)
    #
    # NOTE: with flannel-backend=host-gw there is NO flannel.1 vxlan device.
    # Cross-node traffic uses direct routes via tailscale0 (already trusted
    # by the host's network module).
    #
    # Pod-to-pod FORWARD traffic is managed by k3s's embedded kube-proxy
    # iptables rules, not by the NixOS firewall. The kernel modules and
    # sysctl settings above ensure those rules apply correctly to bridged
    # traffic.
    #
    # k3s inter-node ports (6443, 2379/2380, 10250) are covered by the host
    # trusting tailscale0 (set in the host's network module) — they must NOT
    # be opened on the physical interface.
    # -------------------------------------------------------------------------
    networking.firewall.trustedInterfaces = [
      "cni0"
    ];

  };
}
