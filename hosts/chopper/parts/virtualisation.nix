# hosts/chopper/parts/virtualisation.nix
# Docker and Podman disabled — k3s uses containerd for all container
# workloads. No standalone Docker containers are needed on this node.
{ ... }:
{
  virtualisation = {
    docker.enable = false;
    podman.enable = false;
  };
}
