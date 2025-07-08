{ config, pkgs, lib, ... }:

let
  # Overlay for building the conduit toolbox utility from source
  conduitToolboxOverlay = self: super: {
    conduit_toolbox = super.rustPlatform.buildRustPackage rec {
      pname = "conduit-toolbox";
      version = "0.1.0";
      src = super.fetchFromGitHub {
        owner = "ShadowJonathan";
        repo = "conduit_toolbox";
        rev = "master";
        sha256 = "1szf595kdljz8hlrhg1q6y7iylhdzakpq4kplj37xhynx9nggwvp";
      };
      cargoHash = "sha256-8af4TI4byqZOCof2cZdc4ACgJebmelgYmtn4Ta7/uII=";

      nativeBuildInputs = with super; [ pkg-config clang llvm ];
      buildInputs = with super; [
        rocksdb
      ] ++ lib.optionals super.stdenv.isDarwin [
        super.darwin.apple_sdk.frameworks.Security
      ];

      LIBCLANG_PATH = "${super.libclang.lib}/lib";
      BINDGEN_EXTRA_CLANG_ARGS = "-I${super.clang}/resource-root/include";
    };
  };
in
{
  nixpkgs.overlays = [ conduitToolboxOverlay ];

  services.matrix-conduit = {
    enable = false;
    # package = pkgs.conduwuit;
    # settings.global = { ... };
    # extraEnvironment = { ... };
  };

  environment.systemPackages = with pkgs; [
  ];
}
