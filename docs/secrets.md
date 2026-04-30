# Secrets Management

This repository uses [sops-nix](https://github.com/Mic92/sops-nix) with
[age](https://github.com/FiloSottile/age) encryption. No `ssh-to-age` —
all keys are generated directly with `age-keygen`.

## Key hierarchy

```
Master key (your primary device)
├── Can decrypt ALL secrets across every host
├── Private key: stored safely offline (password manager, encrypted USB)
└── Public key: listed in .sops.yaml as &master

Host keys (one per managed machine)
├── Can ONLY decrypt secrets for that specific host
├── Private key: /var/lib/sops-nix/key.txt on the host
└── Public key: listed in .sops.yaml under &<hostname>
```

## Initial setup (one time)

### 1. Generate the master key

On your primary machine:

```sh
age-keygen -o master.key
# age-keygen: output: age1abc123...  ← this is your PUBLIC key
# The file master.key contains the PRIVATE key
```

**Store the private key safely** — password manager, encrypted USB, etc.
Add the public key to `.sops.yaml` under `&master`.

### 2. Set up your editing environment

sops needs the master private key to encrypt/decrypt. Tell it where to find it:

```sh
# Option A: environment variable (recommended)
export SOPS_AGE_KEY_FILE=/path/to/master.key

# Option B: default location
mkdir -p ~/.config/sops/age
cp master.key ~/.config/sops/age/keys.txt
```

## Adding secrets for a host

### 1. Generate the host key

On the target machine:

```sh
sudo mkdir -p /var/lib/sops-nix
sudo age-keygen -o /var/lib/sops-nix/key.txt
# age-keygen: output: age1xyz789...  ← this is the host's PUBLIC key
sudo chmod 600 /var/lib/sops-nix/key.txt
```

### 2. Register the host key in `.sops.yaml`

Add the host's public key and a creation rule:

```yaml
keys:
  - &master age1abc123...          # your master key (already there)
  - &newhost age1xyz789...         # the new host's public key

creation_rules:
  - path_regex: secrets/newhost/.*
    key_groups:
      - age:
          - *master                # you can always decrypt
          - *newhost               # the host can decrypt its own secrets
```

### 3. Create the secrets file

```sh
mkdir -p secrets/newhost
sops secrets/newhost/secrets.yaml
# Your editor opens — add key: value pairs, save, and sops encrypts it
```

### 4. Wire sops.nix into the host

Create `hosts/<hostname>/sops.nix` (see `hosts/chopper/sops.nix` for example)
and add it to the host's imports.

## Edit existing secrets

```sh
# Make sure SOPS_AGE_KEY_FILE points to your master key
sops secrets/chopper/secrets.yaml
```

This decrypts in-place, opens your `$EDITOR`, and re-encrypts on save.

## Rotate a host key

If a host's key is compromised or you need to regenerate:

```sh
# On the host: generate a new key
sudo age-keygen -o /var/lib/sops-nix/key.txt

# On your machine: update .sops.yaml with the new public key, then:
sops updatekeys secrets/<hostname>/secrets.yaml
```

## Rotate the master key

```sh
# Generate a new master key
age-keygen -o new-master.key

# Update .sops.yaml with the new public key
# Re-encrypt every secrets file:
find secrets -name '*.yaml' -exec sops updatekeys {} \;
```

## Current secrets

| Host | Secret | Used by |
|------|--------|---------|
| chopper | `tailscale-auth-key` | `services.tailscale.authKeyFile` |
| chopper | `nextcloud-admin-pass` | `services.nextcloud.config.adminpassFile` |
| chopper | `cloudflared-tunnel-credentials` | `services.cloudflared.tunnels.*.credentialsFile` |
| chopper | `cloudflare-cert` | `services.cloudflared-dns.certificateFile` (see [`cloudflare.md`](./cloudflare.md)) |

## How sops-nix decrypts at boot

1. NixOS activates the `sops-nix` module
2. It reads the private key from `/var/lib/sops-nix/key.txt`
3. It decrypts each declared secret from `secrets/<host>/secrets.yaml`
4. Decrypted values are placed at `/run/secrets/<name>` (tmpfs — never on disk)
5. Services reference these paths (e.g. `authKeyFile = "/run/secrets/tailscale-auth-key"`)
