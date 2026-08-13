{ lib
, buildGoModule
, fetchFromGitHub
, nodejs
, fetchNpmDeps
, stdenv
,
}:

let
  version = "0.2606.0";

  src = fetchFromGitHub {
    owner = "gomuks";
    repo = "gomuks";
    rev = "v${version}";
    hash = "sha256-Q4hu3bcB16iuqASZvlv7nDvxj8CFX66qWp6DHIUTmh4=";
  };

  vendorHash = "sha256-iuSu5MvNRt+eCZ9wxUwMo6X0joos7q9WPyXBwhn/0yE=";

  # Build the data generator tool (pkg/hicli/cmdspec/print)
  data-generator = buildGoModule {
    pname = "gomuks-print";
    inherit version src vendorHash;

    proxyVendor = true;
    doCheck = false;

    subPackages = [ "pkg/hicli/cmdspec/print" ];

    installPhase = ''
      mkdir -p $out/bin
      cp "$GOPATH/bin/print" "$out/bin/"
    '';
  };

  # Build the WASM binary for the web frontend (cross-compiled to js/wasm)
  wasm = buildGoModule {
    pname = "gomuks-wasm";
    inherit version src vendorHash;

    proxyVendor = true;
    doCheck = false;

    buildPhase = ''
      runHook preBuild

      MAUTRIX_VERSION=$(grep 'maunium.net/go/mautrix ' go.mod | head -n1 | awk '{ print $2 }')
      GOOS=js GOARCH=wasm CGO_ENABLED=0 go build \
        -ldflags "-X go.mau.fi/gomuks/version.Tag=v${version} -X go.mau.fi/gomuks/version.Commit=${src.rev} -X 'go.mau.fi/gomuks/version.BuildTime=0' -X 'maunium.net/go/mautrix.GoModVersion=$MAUTRIX_VERSION'" \
        -o _gomuks.wasm \
        -tags "goolm sqlite_fts5" \
        ./cmd/wasmuks

      runHook postBuild
    '';

    installPhase = ''
      mkdir -p $out
      cp _gomuks.wasm $out/
    '';
  };

  # Build the web frontend (TypeScript + Vite)
  web-frontend = stdenv.mkDerivation {
    pname = "gomuks-web-frontend";
    inherit version src;

    nativeBuildInputs = [ nodejs ];

    npmDeps = fetchNpmDeps {
      src = "${src}/web";
      hash = "sha256-RiOes+tmAxhA9IkyA6yWQXTjjXyZg2Z8FmPTgcmCg/g=";
    };

    buildPhase = ''
      export HOME="$TMPDIR"
      pushd web

      # Generate Go data files for TypeScript
      ${data-generator}/bin/print \
        src/api/types/stdcommands.json \
        src/api/types/stdcommands.d.ts \
        src/api/types/commandtestdata

      # Copy pre-built WASM
      cp ${wasm}/_gomuks.wasm src/api/wasm/_gomuks.wasm

      # Install npm deps and build
      npm ci --offline --cache "$npmDeps" --ignore-scripts --no-audit --no-fund --loglevel=warn
      npm run build -- --logLevel=silent

      popd
    '';

    installPhase = ''
      cp -r web/dist $out
    '';
  };
in
buildGoModule rec {
  pname = "gomuks";
  inherit version src vendorHash;

  proxyVendor = true;
  doCheck = false;

  preBuild = ''
    cp -r ${web-frontend} web/dist
    chmod -R +w web/dist
  '';

  tags = [
    "goolm"
    "sqlite_fts5"
  ];

  subPackages = [
    "cmd/gomuks"
  ];

  ldflags = [
    "-X 'go.mau.fi/gomuks/version.Tag=v${version}'"
    "-X 'go.mau.fi/gomuks/version.Commit=${src.rev}'"
    "-X 'go.mau.fi/gomuks/version.BuildTime=0'"
  ];

  meta = {
    mainProgram = "gomuks";
    description = "Matrix client written in Go (backend with web frontend)";
    homepage = "https://github.com/gomuks/gomuks";
    license = lib.licenses.agpl3Only;
    platforms = lib.platforms.unix;
  };
}
