{ lib
, stdenv
, fetchurl
, makeWrapper
, autoPatchelfHook
, glibc
, gcc-unwrapped
, zlib
, openssl
, postgresql
,
}:
stdenv.mkDerivation rec {
  pname = "neondb-bin";
  version = "1.0.0";

  src = fetchurl {
    url = "https://github.com/Percona-Lab/neon/releases/download/v${version}/neondatabase-neon-PG15-${version}-Linux-x86_64.glibc2.35.tar.gz";
    sha256 = "1a6lsdbq5kmwdap8yqskwj12cfg82ji44i3zfh7m536s0hxjglgg";
  };

  nativeBuildInputs = [
    makeWrapper
    autoPatchelfHook
  ];

  buildInputs = [
    glibc
    gcc-unwrapped.lib
    zlib
    openssl
    postgresql.lib
  ];

  sourceRoot = ".";

  unpackPhase = ''
    runHook preUnpack
    tar -xzf $src
    sourceRoot=$(tar -tzf $src | head -1 | cut -f1 -d/)
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall
    
    mkdir -p $out/bin
    mkdir -p $out/lib
    mkdir -p $out/share
    
    # Copy all files preserving structure
    cp -r * $out/
    
    # Find and make executables in bin directories
    find $out -type f -executable -exec chmod +x {} \;
    
    # Look for the actual neon binaries and create symlinks/wrappers
    if [ -d "$out/target/release" ]; then
      for binary in $out/target/release/*; do
        if [ -x "$binary" ] && [ -f "$binary" ]; then
          ln -sf "$binary" "$out/bin/$(basename $binary)"
        fi
      done
    fi
    
    # Check for neon_local specifically
    find $out -name "neon_local" -type f -executable | head -1 | while read binary; do
      if [ -n "$binary" ]; then
        ln -sf "$binary" "$out/bin/neon_local"
      fi
    done
    
    # Check for other neon binaries
    for name in neon neon_local pageserver safekeeper proxy compute_ctl; do
      find $out -name "$name" -type f -executable | head -1 | while read binary; do
        if [ -n "$binary" ]; then
          ln -sf "$binary" "$out/bin/$name"
        fi
      done
    done
    
    # List what we have
    echo "=== Contents of $out ==="
    find $out -type f -executable | sort
    echo "=== Binaries in $out/bin ==="
    ls -la $out/bin/ || true
    
    runHook postInstall
  '';

  # Skip phases that might cause issues
  dontBuild = true;
  dontConfigure = true;

  meta = with lib; {
    homepage = "https://neon.tech/";
    description = "Neon is a serverless open-source alternative to AWS Aurora Postgres";
    license = licenses.asl20;
    maintainers = with maintainers; [ ];
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ sourceTypes.binaryNativeCode ];
  };
}
