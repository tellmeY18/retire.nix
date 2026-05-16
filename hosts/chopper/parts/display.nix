# hosts/chopper/parts/display.nix
# Display stack disabled — chopper is a headless k3s server node
# managed exclusively via deploy-rs. No local GUI needed.
#
# To re-enable for local desktop use, uncomment the blocks below
# and add "wayland" back to metadata.nix roles.
{ ... }:
{
  # Headless — no greeter, no Sway, no audio.
}
