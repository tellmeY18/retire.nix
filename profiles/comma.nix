# profiles/comma.nix — `,` (comma) on every machine, backed by a prebuilt index.
#
# `, <command>` runs a program from nixpkgs without installing it. It needs a
# nix-index database to know which package provides a command; building that
# index locally takes minutes and goes stale, so we use the prebuilt one from
# nix-index-database (`comma-with-db`).
#
# Wired into the host factories in lib/default.nix, NOT imported per host, so
# every current AND future machine gets it with no extra wiring.
#
# NOTE: only `comma.enable` is set here because that is the one option BOTH
# the NixOS and nix-darwin modules define. The NixOS module additionally has
# an umbrella `programs.nix-index-database.enable` that gates its config block
# (and flips command-not-found off); that option does not exist on darwin, so
# the NixOS factory sets it separately. Setting it here breaks darwin eval
# with "The option `programs.nix-index-database.enable' does not exist".
{
  programs.nix-index-database.comma.enable = true;
}
