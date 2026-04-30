{
  projectRootFile = "flake.nix";
  programs = {
    nixpkgs-fmt.enable = true;
    shfmt.enable = true;
    mdformat.enable = true;
  };
}
