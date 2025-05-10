{ config, pkgs, lib, ... }:
let
  myOverlays = [
    (self: super: {
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

        # Add build dependencies for bindgen/libclang
        nativeBuildInputs = with super; [
          pkg-config
          clang
          llvm
        ];

        buildInputs = with super; [
          # RocksDB dependencies
          rocksdb
        ] ++ lib.optionals super.stdenv.isDarwin [
          super.darwin.apple_sdk.frameworks.Security
        ];

        # Set environment variables for bindgen
        LIBCLANG_PATH = "${super.libclang.lib}/lib";
        BINDGEN_EXTRA_CLANG_ARGS = "-I${super.clang}/resource-root/include";

        # If RocksDB linking issues, you might need:
        # ROCKSDB_INCLUDE_DIR = "${super.rocksdb}/include";
        # ROCKSDB_LIB_DIR = "${super.rocksdb}/lib";
      };
    })
  ];
in
{
  nixpkgs.overlays = myOverlays;

  services.matrix-conduit = {
    enable = true;
    package = pkgs.conduwuit;
    settings.global = {
      server_name = "chat.tellmey.tech";
      port = 6167;
      address = "127.0.0.1";
      allow_registration = true;
      registration_token = "iTdBZW900Zs1VpM+OrAMbvzY9G950jSp7UrgwoE+8Pw=";
      allow_encryption = true;
      allow_federation = true;
      #      trusted_servers        = [ "puppygock.gay" "matrix.org" "sinanmohd.com" ];
      max_request_size = 20000000;
      database_backend = "rocksdb";
      allow_check_for_updates = false;
    };
    extraEnvironment = {
      RUST_BACKTRACE = "1";
      RUST_LOG = "info";
    };
  };

  environment.systemPackages = with pkgs; [
    conduit_toolbox
  ];
}
