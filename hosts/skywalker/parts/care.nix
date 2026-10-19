# hosts/skywalker/parts/care.nix — care-nix Healthcare OS profile.
#
# Brings a single-node k3s + CNCM (CARE manager, portal on localhost:8080),
# a `care` user, and CARE-branded GNOME/Plymouth. Module comes from the
# `care-nix` flake input.
{ ... }:
{
  healthcareos = {
    enable = true;
    # Don't ship the well-known "care" password; set one with
    # `passwd care` as root after first switch (account is wheel).
    user.initialPassword = null;
  };
}
