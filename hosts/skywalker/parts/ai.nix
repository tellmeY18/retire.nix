# hosts/skywalker/parts/ai.nix — Ollama, CUDA-accelerated.
#
# WHY NATIVE RATHER THAN CONTAINERS OR K3S
# ----------------------------------------
# The usual objection to building a CUDA stack natively is that it means
# compiling ~3 GB of uncached, unfree dependencies on a 4-core desktop. That
# does not apply here: this repo's CI builds every host in .#ciMatrix on a
# GitHub runner and pushes the closure to Attic, and skywalker has
# cache.tellmey.fyi/system as a substituter. So CI pays the build cost once
# and this box downloads the result.
#
# k3s was the other candidate and was rejected on measurements: a kubelet +
# containerd baseline is ~600 MB-1 GB on a 7.7 GB machine (12%+ of the
# scarcest resource here), and this cluster's flannel host-gw topology keeps
# hardcoded peer routes in every host's network.nix — so a 4th node would
# mean editing and redeploying chopper, c3po and kenobi, the last of which is
# the sole control plane. Revisit once the second DIMM lands.
#
# HARDWARE REALITY (measured, see the GTX 1060 notes in nvidia.nix)
#   FP32 4.83 TFLOPS · VRAM 6 GB @ 160 GB/s measured · no tensor cores,
#   no bf16, FP16 math at 1/64 rate.
# Decode speed is bandwidth-bound, not compute-bound: expect ~22-32 tok/s on
# a 7-8B Q4_K_M, ~55-70 on a 3B. Prefer GQA models (Llama-3.x, Qwen2.5) —
# an older MHA 7B burns ~2 GB of KV cache at 4K context versus ~512 MB for
# GQA, which is the difference between fitting and not fitting in 6 GB.
{ pkgs, ... }:
{
  services.ollama = {
    enable = true;
    # `services.ollama.acceleration = "cuda"` was removed upstream; the CUDA
    # build is selected by package now. Using the wrong one here is silent —
    # plain `pkgs.ollama` runs happily on CPU at a fraction of the speed.
    package = pkgs.ollama-cuda;

    # Bind on all interfaces, not just the tailnet IP: binding a specific
    # address makes the unit fail if tailscale0 has not come up yet, which
    # turns a transient network hiccup into a dead service. Exposure is
    # controlled by the firewall instead — parts/network.nix opens only
    # port 22 on the LAN and trusts tailscale0, so Ollama is reachable at
    # skywalker.tail477f2f.ts.net:11434 from the tailnet and nowhere else.
    host = "0.0.0.0";
    port = 11434;

    # Models are large and must survive redeploys and GC. /var is its own
    # ZFS dataset, so this is snapshotted with the rest of the system.
    home = "/var/lib/ollama";

    environmentVariables = {
      # Unload an idle model instead of holding 6 GB of VRAM hostage. On a
      # single-GPU box with nothing else to fall back on, a stuck model means
      # the next request OOMs rather than queues.
      OLLAMA_KEEP_ALIVE = "5m";
      # One model resident at a time. 6 GB does not fit two useful models,
      # and the default would happily try.
      OLLAMA_MAX_LOADED_MODELS = "1";
    };
  };

  # Build ONLY for sm_61 (Pascal / GP106).
  #
  # Two reasons, and the first has bitten this host before: nixpkgs' default
  # CUDA capability set does not always include 6.1, and a build that omits
  # it produces a binary that silently ignores the GPU and falls back to CPU
  # — the same failure mode as the 595-driver trap documented in nvidia.nix,
  # equally quiet. Second, restricting to one architecture avoids compiling
  # kernels for a dozen others, which meaningfully cuts CI build time and
  # closure size.
  #
  # Scoped to this host's nixpkgs instance. Note this is NOT
  # `nixpkgs.config.cudaSupport`, which would rebuild the world with CUDA.
  nixpkgs.config.cudaCapabilities = [ "6.1" ];
}
