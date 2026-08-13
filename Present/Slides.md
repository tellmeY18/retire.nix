---
title: "**The Cluster as a Single Declarative Artifact**"
sub_title: "NixOS · K3s · ZFS · Tailscale · SOPS — one repo, every machine"
author: Vysakh Premkumar
event: Cloud Native Summit Kerala 2026
location: Kochi
date: 2026-08-22
theme:
  path: theme.yaml
---

<!-- no_footer -->
<!-- jump_to_middle -->
<!-- alignment: center -->
<!-- font_size: 2 -->

**<span class="on-brand">ONE REPO.</span>**

**<span class="on-brand">THREE MACHINES.</span>**

**<span class="on-brand">ONE COMMAND.</span>**

<span class="meta-on-brand">Cloud Native Summit Kerala 2026 · Kochi</span>

<!-- end_slide -->

<span class="kicker">AGENDA</span>

Agenda
===

<span class="kicker">01</span> **The Problem** — <span class="meta">snowflake servers</span>

<span class="kicker">02</span> **The Flake** — <span class="meta">the whole platform, in code</span>

<span class="kicker">03</span> **Provisioning** — <span class="meta">nixos-anywhere · disko</span>

<span class="kicker">04</span> **Storage · Network · Secrets** — <span class="meta">ZFS · Tailscale · SOPS</span>

<span class="kicker">05</span> **The Payoff** — <span class="meta">why drift can't happen</span>

<!-- end_slide -->

<!-- no_footer -->
<!-- jump_to_middle -->
<!-- alignment: center -->
<!-- font_size: 2 -->

<span class="kicker-dark">PART 1</span>

**<span class="plate-ink">THE PROBLEM</span>**

<span class="meta">every node a snowflake</span>

<!-- end_slide -->

<span class="kicker">DRIFT</span>

Snowflake servers
===

<!-- column_layout: [1, 1] -->

<!-- column: 0 -->

**TODAY**

- emergency package installs
- one-off hotfixes, forgotten cron jobs
- config that lives in shell history
- two years on: no two nodes alike

<!-- column: 1 -->

**<span class="stat">TARGET</span>**

- OS, disk, k3s, ZFS, secrets — **in code**
- the repo is the **single source of truth**
- rebuild a node = **replay the declaration**
- drift isn't managed — it **cannot happen**

<!-- reset_layout -->

<!-- end_slide -->

<!-- no_footer -->
<!-- jump_to_middle -->
<!-- alignment: center -->
<!-- font_size: 2 -->

<span class="kicker-dark">PART 2</span>

**<span class="plate-ink">THE FLAKE</span>**

<span class="meta">one repo · every machine</span>

<!-- end_slide -->

<span class="kicker">THE REPO</span>

One flake, every machine
===

```bash
.
├── flake.nix           # inputs + outputs
├── flake.lock          # pinned, content-hashed
├── lib/                # mkHost + auto-discovery
├── hosts/              # ONE FOLDER PER MACHINE
│   ├── chopper/        #   metadata.nix + configuration.nix
│   ├── kenobi/
│   └── c3po/
├── profiles/           # base · server · k3s · zfs
├── modules/services/   # k3s · tailscale · ...
├── secrets/<host>/     # sops-encrypted, per host
└── k8s/                # helmfile + manifests
```

<!-- pause -->

Adding a machine = **one directory**. The flake finds it.

<!-- end_slide -->

<!-- no_footer -->
<!-- jump_to_middle -->
<!-- alignment: center -->
<!-- font_size: 2 -->

<span class="kicker-dark">PART 3</span>

**<span class="plate-ink">PROVISIONING</span>**

<span class="meta">from a cloud image to NixOS, one command</span>

<!-- end_slide -->

<!-- no_footer -->

![](Images/nixos-anywhere.png)

<span class="kicker-dark">THE CLOUD TRICK</span>

**<span class="plate-ink">nixos-anywhere — any running Linux → NixOS, over SSH</span>**

<!-- end_slide -->

<span class="kicker">NIXOS-ANYWHERE</span>

A new node, from the flake
===

<!-- column_layout: [1, 1, 1] -->

<!-- column: 0 -->

**<span class="stat">STAGE 01</span>**

SSH into the running Linux
no USB · no ISO · no console

<!-- column: 1 -->

**<span class="stat">STAGE 02</span>**

kexec a NixOS installer into RAM
old OS gone · disk is free

<!-- column: 2 -->

**<span class="stat">STAGE 03</span>**

disko partitions as declared
install · reboot · pure NixOS

<!-- reset_layout -->

<!-- pause -->

<!-- new_line -->

```bash
nix run github:nix-community/nixos-anywhere \
  -- --flake .#kenobi root@<ip>
```

<!-- end_slide -->

<span class="kicker">DISKO</span>

The disk is code
===

```nix
disko.devices = {
  disk.nvme0n1 = {
    type = "disk";
    content = {
      type = "gpt";
      partitions = {
        ESP  = { size = "500M"; type = "EF00"; };
        swap = { size = "16G"; type = "8200"; };
        pool = { size = "100%"; type = "bf00"; };
      };
    };
  };
  zpool.rpool.datasets = {
    "nixos/root"    = { mountpoint = "/"; };
    "nixos/nix"     = { mountpoint = "/nix"; };
    "rpool/openebs" = {
      mountpoint = "none";
      options.recordsize  = "8K";
      options.compression = "zstd";
    };
  };
};
```

<!-- pause -->

No bash history. No partition tables in a drawer.
**The disk layout ships in the repo.**

<!-- speaker_note: |
  disko turns install steps into Nix. The same declaration that built kenobi
  rebuilds chopper. ZFS datasets — including the OpenEBS PVC pool — are
  declared too, so storage layouts are reproducible as well.
-->

<!-- end_slide -->

<!-- no_footer -->
<!-- jump_to_middle -->
<!-- alignment: center -->
<!-- font_size: 2 -->

<span class="kicker-dark">PART 4</span>

**<span class="plate-ink">STORAGE · NETWORK · SECRETS</span>**

<span class="meta">ZFS · Tailscale · SOPS</span>

<!-- end_slide -->

<span class="kicker">THE UNDERLAY</span>

Invisible, by default
===

<!-- column_layout: [1, 1] -->

<!-- column: 0 -->

**TAILSCALE — THE NETWORK**

```nix
services.k3s-cluster = {
  enable = true;
  role = "server-init";
  extraFlags = [
    "--flannel-iface=tailscale0"
    "--node-ip=100.107.213.17"
    "--tls-san=k3s-cp.ts.net"
  ];
};
```

<!-- column: 1 -->

**SOPS — THE SECRETS**

```nix
sops.secrets."k3s-token" = {
  sopsFile = ../secrets/chopper.yaml;
};

services.k3s-cluster.tokenFile =
  config.sops.secrets."k3s-token".path;
```

<!-- reset_layout -->

<!-- pause -->

<!-- new_line -->

- **Tailscale** — every cluster port on `tailscale0`, invisible off the tailnet
- **SOPS + age** — secrets committed encrypted, decrypted only on their host

<!-- end_slide -->

<span class="kicker">WHY IT STICKS</span>

The numbers
===

<!-- column_layout: [1, 1, 1] -->

<!-- column: 0 -->

**<span class="stat">5 MIN</span>**

<span class="meta">Ubuntu VM → NixOS node</span>

<!-- column: 1 -->

**<span class="stat">1.5–2×</span>**

<span class="meta">ZFS lz4, invisible</span>

<!-- column: 2 -->

**<span class="stat">0</span>**

<span class="meta">drift · plaintext secrets · open ports</span>

<!-- reset_layout -->

<!-- end_slide -->

<!-- no_footer -->
<!-- jump_to_middle -->
<!-- alignment: center -->
<!-- font_size: 2 -->

**<span class="pull">When the entire platform is declarative,</span>**

**<span class="pull">infrastructure drift stops being something to manage</span>**

**<span class="pull">and becomes something that simply cannot happen.</span>**

<span class="meta">— Vysakh Premkumar</span>

<!-- end_slide -->

<span class="kicker">COMMUNITY</span>

Thanks
===

<!-- alignment: center -->

| Open Healthcare Network | 10BedICU |
| ----------------------- | -------- |
| FOSSCell NIT Calicut    | GLUG NITC |

<!-- pause -->

<!-- new_line -->

This cluster is a community project. So is this talk.

<!-- end_slide -->

<!-- no_footer -->
<!-- jump_to_middle -->
<!-- alignment: center -->
<!-- font_size: 2 -->

**<span class="on-brand">THANK YOU</span>**

<span class="on-brand">the cluster as a single declarative artifact</span>

**<span class="plate-brand">github.com/tellmeY18/retire.nix</span>**

<span class="meta-on-brand">2026-08-22 · Cloud Native Summit Kerala · Kochi</span>

<!-- end_slide -->
