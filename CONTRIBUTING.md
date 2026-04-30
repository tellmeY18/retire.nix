# Contributing

Thanks for hacking on this flake! This guide covers the basics.

## Formatting

```sh
nix fmt          # runs nixpkgs-fmt on all .nix files
```

A move to **treefmt-nix** (nix + shell + markdown) is planned — see
`ROADMAP.md`. Until then, just make sure `nix fmt` is clean before
pushing.

## Commit Style

[Conventional Commits](https://www.conventionalcommits.org/) preferred:

```
feat(home): add starship prompt module
fix(chopper): correct ZFS scrub timer
docs: rewrite README to match repo structure
chore: update flake inputs
```

Common scopes: `darwin`, `chopper`, `home`, `modules`, `packages`, `ci`.

## Branch Naming

```
feat/<short-description>
fix/<short-description>
docs/<short-description>
chore/<short-description>
```

Keep branches short-lived; rebase on `main` before merging.

## Adding a Host

> A full guide will live at `docs/add-a-host.md` once created.

Quick version:

1. Create `hosts/<name>/` with at least `configuration.nix`.
2. Add a `nixosConfigurations.<name>` (or `darwinConfigurations.<name>`)
   entry in `flake.nix`.
3. If using Home Manager, create `home/<name>/default.nix` and a
   corresponding `homeConfigurations` entry.

## Adding a Home Manager Module

1. Create `home/common/<module>/default.nix` (cross-platform) or
   `home/<host>/<module>/default.nix` (host-specific).
2. Import it from the parent `default.nix`.
3. Rebuild to test: `nh darwin switch .` / `nh os switch .`.

See `home/README.md` for more detail.

## Adding a NixOS Service Module

1. Create `modules/<service>.nix`.
2. Import it from the host configuration that needs it.
3. Ideally expose `options.services.<name>.enable` so the module is
   opt-in.

## Linting (optional, not yet in CI)

```sh
nix run nixpkgs#statix -- check .
nix run nixpkgs#deadnix -- .
```

These will be added to CI in a future milestone.

## Questions?

Open an issue or check `CLAUDE.md` and `ROADMAP.md` for project context.
