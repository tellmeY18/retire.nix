{
  lib,
  stdenv,
  fetchurl,
  makeWrapper,
}:
stdenv.mkDerivation rec {
  pname = "neondb-bin";
  version = "1.0.0";

  src = fetchurl {
    url = "https://github.com/Percona-Lab/neon/releases/download/v${version}/neondatabase-neon-PG15-${version}-Linux-x86_64.glibc2.35.tar.gz";
    sha256 = "1a6lsdbq5kmwdap8yqskwj12cfg82ji44i3zfh7m536s0hxjglgg";
  };

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    tar -xzf $src -C $out --strip-components=1

    runHook postInstall
  '';

  meta = {
    homepage = "https://neon.tech/";
    description = "Neon is a serverless open-source alternative to AWS Aurora Postgres. It separates storage and compute and substitutes the PostgreSQL storage layer by redistributing data across a cluster of nodes.";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ ];
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
