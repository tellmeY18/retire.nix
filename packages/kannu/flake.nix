{
  description = "Kannu — macOS notch utility showing AI coding agent status (unofficial Nix packaging)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs =
    { self, nixpkgs }:
    let
      system = "aarch64-darwin";
      pkgs = import nixpkgs { inherit system; };
      kannu = pkgs.callPackage ./default.nix { };
    in
    {
      packages.${system} = {
        inherit kannu;
        default = kannu;
      };

      overlays.default = final: _prev: { inherit kannu; };
    };
}
